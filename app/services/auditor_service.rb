# frozen_string_literal: true

class AuditorService
  def self.track(user:, action:, request:, trackable: nil)
    ip = extract_real_ip(request)
    user_agent = request.user_agent

    Rails.logger.info "[AuditorService] IP detectada: #{ip}"

    location = safe_geocode(ip)

    Rails.logger.info "[AuditorService] Geocoder result: #{location.inspect}"

    UserActivity.create!(
      user: user,
      action: action,
      trackable: trackable ||= user,
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

  def self.extract_real_ip(request)
    ip = request.remote_ip

    if Rails.env.development? && (
      ip == '127.0.0.1' ||
        ip.start_with?('192.168') ||
        ip.start_with?('172.')
    )

      return '8.8.8.8' # IP pública para pruebas
    end

    request.headers['X-Forwarded-For']&.split(',')&.first || ip
  end

  def self.safe_geocode(ip)
    result = Geocoder.search(ip).first
    return nil if result&.data&.dig('bogon')

    result
  rescue StandardError
    nil
  end
end
