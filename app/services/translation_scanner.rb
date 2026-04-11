# app/services/translation_scanner.rb
require 'open3'
require 'yaml'

class TranslationScanner
  def missing_keys
    output, _status = Open3.capture2('bundle exec i18n-tasks missing --format yaml')
    data = YAML.safe_load(output) || {}

    result = []

    data.each do |locale, keys_or_hash|
      next if locale.to_s == I18n.default_locale.to_s

      flatten_keys(keys_or_hash).each do |key|
        result << {
          key: key,
          source_text: fetch_translation(key),
          locale: locale.to_s,
          controller: extract_controller(key),
          view: extract_view(key)
        }
      end
    end

    result
  rescue StandardError => e
    Rails.logger.error "[TranslationScanner] Failed parsing missing keys: #{e.message}"
    []
  end

  private

  # Convierte Hash/Array de YAML a dot notation
  def flatten_keys(obj, parent_key = nil)
    case obj
    when Hash
      obj.flat_map do |k, v|
        full_key = [parent_key, k].compact.join('.')
        flatten_keys(v, full_key)
      end
    when Array
      obj.flat_map.with_index do |v, i|
        full_key = [parent_key, i].compact.join('.')
        flatten_keys(v, full_key)
      end
    else
      [parent_key]
    end
  end

  def fetch_translation(key)
    I18n.t(key, locale: I18n.default_locale, default: key)
  end

  def extract_controller(key)
    key.split('.').first
  end

  def extract_view(key)
    key.split('.')[1]
  end
end
