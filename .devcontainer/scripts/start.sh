#!/bin/bash

# Clean up any leftover Overmind socket
rm -f /workspace/.overmind.sock

# Set default admin password
echo "Setting up default admin user..."
bundle exec rails runner "
  user = User.first
  if user
    user.password = 'Password123!'
    user.password_confirmation = 'Password123!'
    user.save!
    puts 'Admin password set to: Password123!'
    puts 'Login email: ' + user.email
  else
    puts 'No user found, creating admin...'
    User.create!(
      email: 'admin@example.com',
      password: 'Password123!',
      password_confirmation: 'Password123!',
      name: 'Admin User',
      confirmed_at: Time.now
    )
    puts 'Admin created!'
    puts 'Login email: admin@example.com'
    puts 'Password: Password123!'
  end
"

# Start the development server
cd /workspace
pnpm dev
