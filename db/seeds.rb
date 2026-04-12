puts "Starting database seeds \n"
# -----------------------------------------------------------------------------------------------------
# LANGUAGES
# -----------------------------------------------------------------------------------------------------
puts "➡️ Creating languages"
Language.find_or_create_by!(name: 'English', code: 'en')
Language.find_or_create_by!(name: 'Spanish', code: 'es')
Language.find_or_create_by(name: 'Portuguese', code: 'pt')

# -----------------------------------------------------------------------------------------------------
# ROLES
# -----------------------------------------------------------------------------------------------------
puts "➡️ Creating roles"
roles = %w[superadmin admin user]
roles.each { |role| Role.find_or_create_by!(name: role) }

# -----------------------------------------------------------------------------------------------------
# PERMISSIONS
# -----------------------------------------------------------------------------------------------------
puts "➡️ Creating permissions"
permissions = %w[users.index users.show users.edit users.update users.destroy users.create roles.index roles.show roles.edit roles.update roles.destroy roles.create roles.toggle_permissions]
permissions.each { |permission| Permission.find_or_create_by!(name: permission) }

# -----------------------------------------------------------------------------------------------------
# ASSIGNMENTS
# -----------------------------------------------------------------------------------------------------
puts "➡️ Assigning permissions to roles "
superadmin = Role.find_by!(name: 'superadmin')
admin = Role.find_by!(name: 'admin')
user = Role.find_by!(name: 'user')

# 🔥 superadmin → all permissions
superadmin.permissions << Permission.all
puts "✔ Superadmin assigned ALL permissions"

# 🔹 admin → limited permissions
admin.permissions << Permission.where(name: %w[users.index users.create users.update])
puts "✔ Admin permissions assigned"

# 🔹 user → basic permissions
user.permissions << Permission.where(name: %w[users.show users.edit])
puts "✔ User permissions assigned"

puts "✔ Seeds completed successfully"