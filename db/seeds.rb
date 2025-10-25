# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin users
if Rails.env.development?
  # Create default admin user
  admin_user = AdminUser.find_or_create_by!(email: 'admin@example.com') do |user|
    user.password = 'password'
    user.password_confirmation = 'password'
  end

  # Create additional admin user
  AdminUser.find_or_create_by!(email: 'superadmin@example.com') do |user|
    user.password = 'admin123'
    user.password_confirmation = 'admin123'
  end

  # Create sample regular users
  users = [
    { email: 'john@example.com', password: 'password123' },
    { email: 'jane@example.com', password: 'password123' },
    { email: 'bob@example.com', password: 'password123' },
    { email: 'alice@example.com', password: 'password123' }
  ]

  users.each do |user_data|
    User.find_or_create_by!(email: user_data[:email]) do |user|
      user.password = user_data[:password]
      user.password_confirmation = user_data[:password]
    end
  end

  puts "✅ Created #{AdminUser.count} admin users"
  puts "✅ Created #{User.count} regular users"
  puts "✅ Admin login: admin@example.com / password"
  puts "✅ Super admin login: superadmin@example.com / admin123"
end