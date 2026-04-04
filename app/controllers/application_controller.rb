class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :track_visit
  before_action :set_paper_trail_whodunnit

  private

  def track_visit
    ahoy.track_visit unless ahoy.visit
  end

  def user_for_paper_trail
    current_user&.id || 'Guest'
  end
end
