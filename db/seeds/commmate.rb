# CommMate Seeds
# Run with: bundle exec rails runner custom/db/seeds_commmate.rb

# Loading installation configs
GlobalConfig.clear_cache
ConfigLoader.new.process

Rails.logger.info '🌱 CommMate Seeding Started...'

# Always ensure onboarding is disabled for CommMate
Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
Rails.logger.info '  ✓ Onboarding disabled'

# Create default CommMate account if doesn't exist
account = Account.find_or_create_by!(name: 'CommMate') do |acc|
  acc.locale = 'pt_BR'
  Rails.logger.info '  ✓ Created default CommMate account'
end

# Update locale if already exists but has wrong locale
if account.locale != 'pt_BR'
  account.update!(locale: 'pt_BR')
  Rails.logger.info '  ✓ Updated account locale to pt_BR'
end

# Create super admin ONLY if no SuperAdmin exists at all
admin_email = ENV.fetch('COMMMATE_ADMIN_EMAIL', 'admin@commmate.com')
admin_password = ENV.fetch('COMMMATE_ADMIN_PASSWORD', 'CommMate123!')

# Check if ANY SuperAdmin exists (not just this specific email)
existing_super_admin = User.where(type: 'SuperAdmin').first

if existing_super_admin
  user = existing_super_admin
  Rails.logger.info "  ✓ Super admin already exists: #{user.email} (not creating new one)"
else
  user = User.new(
    name: 'CommMate Admin',
    email: admin_email,
    password: admin_password,
    type: 'SuperAdmin'
  )
  user.skip_confirmation!
  user.save!
  Rails.logger.info "  ✓ Created super admin: #{admin_email}"
end

# Link super admin to account if not already linked
unless AccountUser.exists?(account_id: account.id, user_id: user.id)
  AccountUser.create!(
    account_id: account.id,
    user_id: user.id,
    role: :administrator
  )
  Rails.logger.info '  ✓ Linked super admin to account'
end

# Enable account signup
config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
config.value = true
config.save!
Rails.logger.info '  ✓ Account signup enabled'

# Enable creating accounts from dashboard
config = InstallationConfig.find_or_initialize_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
config.value = true
config.save!
Rails.logger.info '  ✓ Dashboard account creation enabled'

GlobalConfig.clear_cache

Rails.logger.info ''
Rails.logger.info '✅ CommMate seeding complete!'
Rails.logger.info ''
Rails.logger.info '🔑 Login credentials:'
Rails.logger.info "   Email: #{admin_email}"
Rails.logger.info "   Password: #{admin_password}"
Rails.logger.info ''
