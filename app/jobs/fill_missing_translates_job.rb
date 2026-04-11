# app/jobs/fill_missing_translates_job.rb
require 'net/http'
require 'uri'
require 'json'

class FillMissingTranslatesJob < ApplicationJob
  queue_as :default

  LIBRETRANSLATE_URL = 'https://libretranslate.de/translate/'.freeze
  MAX_RETRIES = 3
  RETRY_WAIT = 2

  private_constant :LIBRETRANSLATE_URL, :MAX_RETRIES, :RETRY_WAIT

  def perform
    Rails.logger.info '[FillMissingTranslatesJob] Starting translation job...'

    missing_translations = TranslationScanner.new.missing_keys
    Rails.logger.info "[FillMissingTranslatesJob] Found #{missing_translations.size} missing translations"

    missing_translations.each do |entry|
      key = entry[:key]
      source_text = entry[:source_text] || ''
      locale_code = entry[:locale] || I18n.default_locale.to_s

      # Si es Hash (pluralization), usar solo :one
      if source_text.is_a?(Hash)
        Rails.logger.info "[FillMissingTranslatesJob] Key #{key} has pluralization hash, using :one for translation"
        source_text = source_text[:one]
      end

      language = Language.find_or_create_by!(code: locale_code)

      translate_record = Translate.find_or_initialize_by(key: key, language: language)
      translate_record.controller = entry[:controller]
      translate_record.view = entry[:view]

      if translate_record.new_record?
        Rails.logger.info "[FillMissingTranslatesJob] Creating new Translate record for #{key} (locale: #{locale_code})"
      else
        Rails.logger.info "[FillMissingTranslatesJob] Found existing Translate record for #{key} (locale: #{locale_code})"
      end

      translate_record.pending!
      translate_record.save!
      Rails.logger.info "[FillMissingTranslatesJob] Translate record saved with status: #{translate_record.status}"

      begin
        translated_text = translate_with_retry(source_text, locale_code)
        Rails.logger.info "[FillMissingTranslatesJob] Translation result for #{key}: #{translated_text}"

        translate_record.update!(value: translated_text)
        translate_record.completed!
        Rails.logger.info "[FillMissingTranslatesJob] Translate record updated with status: #{translate_record.status}"

        update_locale_file(locale_code, key, translated_text)
        Rails.logger.info "[FillMissingTranslatesJob] YAML file updated for locale '#{locale_code}', key: #{key}"
      rescue StandardError => e
        translate_record.failed!
        Rails.logger.error "[FillMissingTranslatesJob] Failed to translate #{key}: #{e.class} - #{e.message}"
      end
    end

    Rails.logger.info '[FillMissingTranslatesJob] Finished translation job.'
  end

  private

  def translate_with_retry(text, target_locale)
    attempts = 0
    begin
      attempts += 1
      translate_text(text, target_locale)
    rescue StandardError => e
      if attempts < MAX_RETRIES
        Rails.logger.warn "[FillMissingTranslatesJob] Retry #{attempts} for text '#{text}' due to #{e.class}"
        sleep RETRY_WAIT
        retry
      else
        Rails.logger.error "[FillMissingTranslatesJob] Max retries reached for text '#{text}': #{e.message}"
        raise e
      end
    end
  end

  def translate_text(text, target_locale)
    uri = URI.parse(LIBRETRANSLATE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(q: text, source: 'en', target: target_locale, format: 'text')

    response = http.request(request)
    raise RuntimeError, "LibreTranslate API returned HTTP #{response.code}" if Integer(response.code, 10) != 200

    result = JSON.parse(response.body)
    result['translatedText'] || text
  end

  def update_locale_file(locale, key, value)
    file_path = Rails.root.join('config', 'locales', "#{locale}.yml")
    locales_data = File.exist?(file_path) ? YAML.load_file(file_path) : {}
    locales_data ||= {}
    locales_data[locale] ||= {}
    insert_nested_key(locales_data[locale], key.split('.'), value)

    File.write(file_path, locales_data.deep_stringify_keys.to_yaml)
  rescue StandardError => e
    Rails.logger.error "[FillMissingTranslatesJob] Failed to update YAML for #{key}: #{e.message}"
  end

  def insert_nested_key(hash, keys, value)
    current = hash
    keys.each_with_index do |k, idx|
      k = k.to_s
      if idx == keys.size - 1
        current[k] = value
      else
        current[k] ||= {}
        current = current[k]
      end
    end
  end
end
