class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = false
Ahoy.geocode = true
Ahoy.track_bots = false
Ahoy.mask_ips = true
Ahoy.server_side_visits = true
Ahoy.user_method = :current_user
