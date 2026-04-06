# app/services/translation_service.rb
require 'net/http'
require 'uri'
require 'json'

# TranslationService
#
# This service handles text translation using the LibreTranslate API.
# It is designed to be type-safe, retry failed requests, and log errors clearly.
#
# Features:
# - Returns the original text if the source and target languages are the same.
# - Retries failed translations up to a maximum number of attempts.
# - Returns translated text as a string, ensuring type safety.
# - Logs warnings and errors to Rails logs for debugging.
#
# Usage:
#   translated_text = TranslationService.translate("Hello", from: "en", to: "es")
#   puts translated_text # => "Hola"
#
# Constants:
#   - API_URL [String]: the endpoint for the LibreTranslate API (private)
#   - MAX_RETRIES [Integer]: maximum number of API retries (private)
#   - RETRY_DELAY [Integer]: delay in seconds between retries (private)
#
# Methods:
#   - .translate(text, from:, to:) -> String or nil
#       Translate a text from a source language to a target language.
#       Returns nil if translation failed after all retries.
#
# @example Translate from English to Spanish
#   TranslationService.translate("Hello", from: "en", to: "es")
#   # => "Hola"
#
# @note This service is intended for use within background jobs or controllers
#       that require automatic translation of missing I18n keys or content.
class TranslationService
  # API URL for LibreTranslate
  API_URL = 'https://libretranslate.de/translate'.freeze
  private_constant :API_URL

  MAX_RETRIES = 3
  RETRY_DELAY = 2.seconds
  private_constant :MAX_RETRIES, :RETRY_DELAY

  # Translate text from source language to target language
  #
  # @param text [String] text to translate
  # @param from [String] source language code (e.g., "en")
  # @param to [String] target language code (e.g., "es")
  # @return [String, nil] translated text or nil if failed
  #
  # @example Translate text from English to Spanish
  #   TranslationService.translate("Hello", from: "en", to: "es")
  #   # => "Hola"
  def self.translate(text, from:, to:)
    # Return original text if no translation is needed
    return text if from == to

    retries = 0

    begin
      response = post_request(text, from, to)
      result = JSON.parse(response.body)
      translated = result['translatedText']
      return translated.to_s if translated

      Rails.logger.warn("[TranslationService] Empty translation received for '#{text}' from #{from} to #{to}")
      nil
    rescue StandardError => e
      retries += 1
      if retries <= MAX_RETRIES
        Rails.logger.warn("[TranslationService] Retry #{retries} for '#{text}' due to error: #{e.message}")
        sleep(RETRY_DELAY)
        retry
      else
        Rails.logger.error("[TranslationService] Translation failed after #{MAX_RETRIES} retries: #{e.message}")
        nil
      end
    end
  end

  private_class_method def self.post_request(text, from, to)
    uri = URI(API_URL)

    # API parameters must have string keys to satisfy type checkers
    params = {
      'q' => text,
      'source' => from,
      'target' => to,
      'format' => 'text'
    }

    Net::HTTP.post_form(uri, params)
  end
end
