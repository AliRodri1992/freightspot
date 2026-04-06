# app/services/translation_scanner.rb

# TranslationScanner
#
# This service scans all application views and Ruby files to extract
# translation keys used with the `t` helper.
#
# It collects keys from:
#   - Views: `.erb`, `.haml`, `.slim`
#   - Ruby files: controllers, helpers, models, jobs, etc.
#
# Each key is returned with metadata about its origin, including the
# controller or view it belongs to.
#
# Example:
#   TranslationScanner.scan_all
#   # => [
#   #      { key: "users.show.title", controller: "users", view: "users/show.html.erb" },
#   #      { key: "flash.notice.saved", controller: "application", view: nil }
#   #    ]
class TranslationScanner
  # Scan all views and Ruby files for translation keys.
  #
  # @return [Array<Hash>] An array of hashes with keys:
  #   - :key[String] the translation key
  #   - :controller[String, nil] the related controller or folder
  #   - :view[String, nil] the view file path relative to app/views
  def self.scan_all
    results = []

    # Scan ERB, HAML, and Slim views
    Rails.root.glob('app/views/**/*.{erb,haml,slim}').each do |file|
      content = File.read(file)
      content.scan(/t\(["'](.+?)["']\)/).flatten.each do |key|
        results << { key: key, controller: controller_from_view(file), view: file.sub(Rails.root.join('app/views/').to_s, '') }
      end
    end

    # Scan Ruby files (controllers, helpers, models, jobs)
    Rails.root.glob('app/**/*.{rb}').each do |file|
      content = File.read(file)
      content.scan(/t\(["'](.+?)["']\)/).flatten.each do |key|
        results << { key: key, controller: controller_from_ruby(file), view: nil }
      end
    end

    results.uniq
  end

  # Extracts controller name from a view path
  #
  # @param view_path [String] full path of the view file
  # @return [String] the controller folder name
  def self.controller_from_view(view_path)
    parts = view_path.split('/app/views/').last.split('/')
    parts.first
  end

  # Extracts controller or folder name from a Ruby file path
  #
  # @param file_path [String] full path of the Ruby file
  # @return [String] the folder name (usually controller, helper, or model)
  def self.controller_from_ruby(file_path)
    parts = file_path.split('/app/').last.split('/')
    parts.first
  end
end
