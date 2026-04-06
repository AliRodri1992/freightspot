# app/services/translation_scanner.rb

# TranslationScanner
#
# This service scans the Rails application for I18n translation keys.
# It inspects both view templates (ERB, HAML, Slim) and Ruby files
# (controllers, helpers, jobs, models) to detect all `t('key')` calls.
#
# Features:
# - Detects translation keys across views and Ruby files.
# - Returns the controller or folder context and the view file path for each key when available.
# - Ensures that results are unique to avoid duplicates.
#
# Usage:
#   results = TranslationScanner.scan_all
#   # => [
#   #      { key: "users.show.title", controller: "users", view: "users/show.html.erb" },
#   #      { key: "welcome.message", controller: "home", view: "home/index.html.erb" }
#   #    ]
#
# Methods:
#   - .scan_all -> Array<Hash>
#       Scans all views and Ruby files for translation keys.
#       Returns an array of hashes with key, controller, and view metadata.
#   - .controller_from_view(view_path) -> String
#       Extracts the controller folder name from a view path.
#   - .controller_from_ruby(file_path) -> String
#       Extracts the main folder name (controller, helper, model, job) from a Ruby file path.
class TranslationScanner
  # Scan all views and Ruby files for translation keys
  #
  # @return [Array<Hash>] An array of hashes with keys:
  #   - :key [String] the translation key
  #   - :controller [String, nil] the related controller or folder
  #   - :view [String, nil] the view file path relative to app/views
  def self.scan_all
    results = []

    # Scan ERB, HAML, and Slim views
    scan_files('app/views/**/*.{erb,haml,slim}') do |file, key|
      results << {
        key: key,
        controller: controller_from_view(file),
        view: file.sub(Rails.root.join('app/views/').to_s, '')
      }
    end

    # Scan Ruby files (controllers, helpers, models, jobs)
    scan_files('app/**/*.{rb}') do |file, key|
      results << {
        key: key,
        controller: controller_from_ruby(file),
        view: nil
      }
    end

    results.uniq
  end

  # Extracts controller name from a view path
  #
  # @param view_path [String] full path of the view file
  # @return [String] the controller folder name
  def self.controller_from_view(view_path)
    view_path.split('/app/views/').last.split('/').first
  rescue StandardError => e
    Rails.logger.warn("[TranslationScanner] Failed to extract controller from view path '#{view_path}': #{e.message}")
    'unknown'
  end

  # Extracts controller or folder name from a Ruby file path
  #
  # @param file_path [String] full path of the Ruby file
  # @return [String] the folder name (usually controller, helper, or model)
  def self.controller_from_ruby(file_path)
    file_path.split('/app/').last.split('/').first
  rescue StandardError => e
    Rails.logger.warn("[TranslationScanner] Failed to extract controller from Ruby path '#{file_path}': #{e.message}")
    'unknown'
  end

  # Helper to safely scan files for translation keys
  #
  # @param glob_pattern [String] file glob pattern
  # @yieldparam file [String] the file path
  # @yieldparam key [String] translation key found
  def self.scan_files(glob_pattern)
    Rails.root.glob(glob_pattern).each do |file|
      content = File.read(file)
      content.scan(/t\(["'](.+?)["']\)/).flatten.each do |key|
        yield(file, key) if block_given?
      end
    rescue StandardError => e
      Rails.logger.warn("[TranslationScanner] Failed to read file '#{file}': #{e.message}")
      next
    end
  end
end
