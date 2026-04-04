# frozen_string_literal: true

class AuditorService
  def self.track(user:, action:, request:, trackable: nil)
    ip = request.remote_ip
    user_agent = request.user_agent
    location = Geocoder.search(ip).first

    UserActivity.create!(
      user: user,
      action: action,
      trackable: trackable,
      ip_address: ip,
      user_agent: user_agent,
      city: location&.city,
      region: location&.region,
      country: location&.country,
      latitude: location&.latitude,
      longitude: location&.longitude
    )
  end

  def self.track_model_change(user:, trackable:, action:, request:)
    PaperTrail.request.whodunnit = user.id
    track(user: user, action: action, trackable: trackable, request: request)
  end
end
