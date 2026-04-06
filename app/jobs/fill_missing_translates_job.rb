# FillMissingTranslatesJob
#
# This job is responsible for scanning all application views and Ruby files
# to detect translation keys, filling missing translations automatically,
# and generating locale YAML files for each language in the database.
#
# The workflow is as follows:
#   1. Scan all views and Ruby files using TranslationScanner.
#   2. For each detected key, check if a Translate record exists for each language.
#   3. If missing or pending, use TranslationService to generate the translation.
#   4. Save the translation to the database with status "processed" or "pending".
#   5. Generate or update YAML files under config/locales/<language_code>.yml
#
# Usage:
#   FillMissingTranslatesJob.perform_later
#
# @example Perform job asynchronously
#   FillMissingTranslatesJob.perform_later
#
# @example Perform job synchronously (for testing)
#   FillMissingTranslatesJob.new.perform
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
# Notes:
#   - Ensures `translate.value` is never nil (type-safe)
#   - Generates YAML files using `File.write` (Rubocop compliant)
#   - Compatible with Rails 8 and RuboCop rules provided
#
# @see TranslationScanner
# @see TranslationService
class FillMissingTranslatesJob < ApplicationJob
  queue_as :default

  # Perform scanning, translation, and YAML generation
  def perform
    scanner_results = TranslationScanner.scan_all
    i18n = I18n::Tasks::BaseTask.new

    Language.find_each do |language|
      scanner_results.each do |entry|
        process_translation(entry, language, i18n)
      end
    end

    generate_locale_files
  end

  private

  # Process a single translation key for a given language
  #
  # @param entry [Hash] Translation key and metadata
  # @param language [Language] Language record
  # @param i18n [I18n::Tasks::BaseTask] I18n-tasks instance
  # @return [void]
  def process_translation(entry, language, i18n)
    translate = Translate.find_or_initialize_by(
      key: entry[:key],
      language: language
    )

    translate.controller ||= entry[:controller]
    translate.view ||= entry[:view]
    return if translate.processed?

    source_text = english_source(entry[:key], language, i18n)
    translated_text = translate_text(source_text, language.code) || source_text

    translate.value = translated_text
    translate.status = translated_text.present? ? 'processed' : 'pending'
    translate.save!
  end

  # Returns English source text for translation
  #
  # Ensures a non-nil string is returned for type safety
  #
  # @param key [String] Translation key
  # @param language [Language] Language record
  # @param i18n [I18n::Tasks::BaseTask] I18n-tasks instance
  # @return [String] Non-nil source text
  def english_source(key, language, i18n)
    return key if language.code == 'en'

    i18n.data['en'].dig(*key.split('.'))&.to_s || key
  end

  # Translate text using TranslationService
  #
  # @param text [String] Source text
  # @param target_code [String] Target language code
  # @return [String, nil] Translated text or nil if failed
  def translate_text(text, target_code)
    return text if target_code == 'en'

    TranslationService.translate(text, from: 'en', to: target_code)
  end

  # Generate YAML files for each language
  #
  # Writes locale YAML files to config/locales/<language_code>.yml
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
    end
  end

  # Insert a translation into a nested hash structure
  #
  # Converts dot-separated keys into nested hashes
  #
  # @param hash [Hash] Root hash
  # @param key [String] Dot-separated key (e.g., "users.show.title")
  # @param value [String] Translation value
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
