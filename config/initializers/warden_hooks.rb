# After login
Warden::Manager.after_set_user except: :fetch do |user, auth, _opts|
  AuditorService.track(
    user: user,
    action: 'login',
    trackable: nil,
    request: auth.request
  )
end

# Before logout
Warden::Manager.before_logout do |user, auth, _opts|
  AuditorService.track(
    user: user,
    action: 'logout',
    trackable: nil,
    request: auth.request
  )
end