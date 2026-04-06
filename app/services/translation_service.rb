# app/services/translation_service.rb
# app/services/translation_service.rb
require 'httparty'

# TranslationService
#
# Provides automatic translation of text between languages using the LibreTranslate API.
# This service is intended for internal use and returns nil if the translation fails.
#
# Example:
#   translated = TranslationService.translate("Hello", to: "es")
#   # => "Hola"
class TranslationService
  # API URL for LibreTranslate
  API_URL = 'https://libretranslate.de/translate'.freeze
  private_constant :API_URL

  # Translate a text from one language to another
  #
  # @param text [String] The text to be translated
  # @param to [String] Target language code (required)
  # @param from [String] Source language code (optional, default:"en")
  # @return [String, nil] The translated text, or nil if translation fails
  #
  # @example Translate text to Spanish
  #   TranslationService.translate("Hello", to: "es")
  #   # => "Hola"
  def self.translate(text, to:, from: 'en')
    response = HTTParty.post(
      API_URL,
      body: {
        q: text,
        source: from,
        target: to,
        format: 'text'
      }
    )

    if response.code == 200
      response.parsed_response['translatedText']
    else
      Rails.logger.error "Error en traducción: #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Excepción en traducción: #{e.message}"
    nil
  end
end
