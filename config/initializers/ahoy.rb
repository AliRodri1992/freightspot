# config/initializers/ahoy.rb

class Ahoy::Store < Ahoy::DatabaseStore
end

Ahoy.api = false
Ahoy.geocode = false
Ahoy.track_bots = false
Ahoy.mask_ips = true
Ahoy.server_side_visits = true
Ahoy.user_method = :current_user

Rails.application.config.after_initialize do
  # Solo se ejecuta después de cargar todos los modelos
  Ahoy::Visit.after_create do |visit|
    ip = visit.ip

    if Rails.env.development? && (ip == "127.0.0.1" || ip.start_with?("192.168") || ip.start_with?("172."))
      ip = "8.8.8.8"
    end

    location = Geocoder.search(ip).first

    if location && !location.data["bogon"]
      visit.update(
        city: location.city,
        region: location.region,
        country: location.country,
        latitude: location.latitude,
        longitude: location.longitude
      )
      Rails.logger.info "[Ahoy] Visit geolocated: #{visit.city}, #{visit.region}, #{visit.country}"
    else
      Rails.logger.info "[Ahoy] Visit IP not geolocatable: #{ip}"
    end
  end
end
