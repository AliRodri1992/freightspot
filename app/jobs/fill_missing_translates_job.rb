# FillMissingTranslatesJob
#
# This job scans all views and Ruby files in the application to detect translation keys,
# fills missing translations using TranslationService, and generates YAML locale files
# for each language stored in the database.
#
# Workflow:
#   1. Scan all views and Ruby files using TranslationScanner.
#   2. For each detected key, check if a Translate record exists for each language.
#   3. If missing or pending, use TranslationService to generate the translation.
#   4. Save the translation to the database with status "processed" or "pending".
#   5. Generate or update YAML files under config/locales/<language_code>.yml
#
# Features:
# - Type-safe translation assignment (translate.value is never nil)
# - Error handling per translation key to avoid stopping the job
# - Logs progress, warnings, and errors for debugging
# - Generates nested YAML files for dot-separated keys
#
# Usage:
#   FillMissingTranslatesJob.perform_later   # Asynchronous execution
#   FillMissingTranslatesJob.new.perform     # Synchronous execution (testing)
#
# Models used:
#   - Language: represents a language in the system (e.g., en, es, fr)
#   - Translate: stores translation keys, values, and metadata
#
# Services used:
#   - TranslationService: handles external translation API calls
#   - TranslationScanner: scans views and Ruby files for translation keys
#
# Generated files:
#   - config/locales/en.yml
#   - config/locales/es.yml
#   - config/locales/fr.yml
#   - ...one YAML per language in the database
#
# @see TranslationService
# @see TranslationScanner
class FillMissingTranslatesJob < ApplicationJob
  queue_as :default

  # Perform scanning, translation, and YAML generation
  #
  # @return [void]
  def perform
    Rails.logger.info('[FillMissingTranslatesJob] Starting translation job...')

    begin
      require 'i18n/tasks'
    rescue LoadError => e
      Rails.logger.error("[FillMissingTranslatesJob] i18n-tasks gem is missing: #{e.message}")
      return
    end

    i18n = I18n::Tasks::BaseTask.new
    scanner_results = TranslationScanner.scan_all
    Rails.logger.info("[FillMissingTranslatesJob] #{scanner_results.size} translation keys detected by scanner")

    Language.find_each do |language|
      next if language.code == 'en' # English is the source language

      # Detect missing keys for this language
      missing_keys = i18n.missing_keys.select { |k| k[:locale].to_s == language.code }.map { |k| k[:key].to_s }
      Rails.logger.info("[FillMissingTranslatesJob] #{missing_keys.size} missing keys for #{language.code}")

      # Only process keys detected by scanner AND missing in this language
      scanner_results.select { |entry| missing_keys.include?(entry[:key]) }.each do |entry|
        process_translation(entry, language)
      end
    end

    generate_locale_files
    Rails.logger.info('[FillMissingTranslatesJob] Translation job finished.')
  rescue StandardError => e
    Rails.logger.error("[FillMissingTranslatesJob] Unexpected error: #{e.class} #{e}")
  end

  private

  # Processes a single translation key for a given language
  #
  # @param entry [Hash] The translation key and metadata (key, controller, view)
  # @param language [Language] The language record
  # @return [void]
  def process_translation(entry, language)
    translate = Translate.find_or_initialize_by(
      key: entry[:key],
      language: language
    )

    translate.controller ||= entry[:controller]
    translate.view ||= entry[:view]
    return if translate.processed?

    source_text = english_source(entry[:key])
    translated_text = translate_text_with_retry(source_text, language.code) || source_text

    translate.value = translated_text
    translate.status = translated_text.present? ? 'processed' : 'pending'
    translate.save!
  rescue StandardError => e
    Rails.logger.error("[FillMissingTranslatesJob] Failed to process key '#{entry[:key]}' for #{language.code}: #{e.message}")
  end

  # Returns the English source text for a translation key
  #
  # @param key [String] The translation key
  # @return [String] The English text or the key itself if not found
  def english_source(key)
    I18n::Tasks::BaseTask.new.data['en'].dig(*key.split('.'))&.to_s || key
  rescue StandardError => e
    Rails.logger.error("[FillMissingTranslatesJob] Failed to fetch English source for '#{key}': #{e.message}")
    key
  end

  # Translates a text string using the TranslationService
  #
  # @param text [String] The source text
  # @param target_code [String] The target language code
  # @return [String, nil] Translated text or nil if translation fails
  def translate_text_with_retry(text, target_code)
    return text if target_code == 'en'

    TranslationService.translate(text, from: 'en', to: target_code)
  rescue StandardError => e
    Rails.logger.error("[FillMissingTranslatesJob] TranslationService failed for '#{text}' to '#{target_code}': #{e.message}")
    nil
  end

  # Generates YAML files for each language
  #
  # Writes nested YAML files under `config/locales/<language_code>.yml`
  #
  # @return [void]
  def generate_locale_files
    Language.find_each do |language|
      locale_data = { language.code => {} }
      language.translates.processed.each do |t|
        insert_translation(locale_data[language.code], t.key, t.value)
      end

      file_path = Rails.root.join("config/locales/#{language.code}.yml")
      File.write(file_path, locale_data.to_yaml)
      Rails.logger.info("[FillMissingTranslatesJob] YAML file generated: #{file_path}")
    rescue StandardError => e
      Rails.logger.error("[FillMissingTranslatesJob] Failed to generate YAML for #{language.code}: #{e.message}")
    end
  end

  # Inserts a translation into a nested hash structure
  #
  # Converts dot-separated keys (e.g., 'users.show.title') into nested hashes
  #
  # @param hash [Hash] The root hash
  # @param key [String] The translation key
  # @param value [String] The translated value
  # @return [void]
  def insert_translation(hash, key, value)
    keys = key.split('.')
    last_key = keys.pop
    current = hash
    keys.each do |k|
      current[k] ||= {}
      current = current[k]
    end
    current[last_key] = value
  end
end
