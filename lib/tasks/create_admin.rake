# frozen_string_literal: true

namespace :chatwoot do
  desc 'Create a new admin user (email, password, name). Example: rake chatwoot:create_admin'
  task create_admin: :environment do
    email = ENV['ADMIN_EMAIL']
    password = ENV['ADMIN_PASSWORD']
    name = ENV['ADMIN_NAME'] || 'Admin'

    if email.blank? || password.blank?
      puts "Usage: ADMIN_EMAIL=x ADMIN_PASSWORD=y [ADMIN_NAME=z] rake chatwoot:create_admin"
      puts "Example: ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD='Abc123456!' rake chatwoot:create_admin"
      exit 1
    end

    account = Account.first
    if account.blank?
      account = Account.create!(name: 'Default')
      puts "Created account: #{account.name} (id=#{account.id})"
    end

    user = User.find_by(email: email)
    if user
      user.update!(password: password, password_confirmation: password, name: name)
      puts "Updated existing user: #{email} (id=#{user.id})"
    else
      user = User.new(email: email, name: name, password: password, password_confirmation: password)
      user.skip_confirmation!
      user.save!
      puts "Created user: #{email} (id=#{user.id})"
    end

    au = AccountUser.find_by(account_id: account.id, user_id: user.id)
    if au
      au.update!(role: :administrator)
      puts "User already in account; role set to administrator."
    else
      AccountUser.create!(account_id: account.id, user_id: user.id, role: :administrator)
      puts "Added user as administrator to account '#{account.name}'."
    end

    puts "Done. Login with: #{email} / (your password)"
  end
end
