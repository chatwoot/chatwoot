# CommMate Initialization Script
# This runs on container startup to configure branding in the database

Rails.logger.info "🎨 Applying CommMate branding to database..."

begin
  # Update branding
  InstallationConfig.find_or_create_by!(name: 'INSTALLATION_NAME').update!(value: 'CommMate')
  InstallationConfig.find_or_create_by!(name: 'BRAND_NAME').update!(value: 'CommMate')
  
  # Update URLs
  InstallationConfig.find_or_create_by!(name: 'BRAND_URL').update!(value: 'https://commmate.com')
  InstallationConfig.find_or_create_by!(name: 'WIDGET_BRAND_URL').update!(value: 'https://commmate.com')
  InstallationConfig.find_or_create_by!(name: 'TERMS_URL').update!(value: 'https://commmate.com/terms')
  InstallationConfig.find_or_create_by!(name: 'PRIVACY_URL').update!(value: 'https://commmate.com/privacy')
  
  # Update logos
  InstallationConfig.find_or_create_by!(name: 'LOGO').update!(value: '/brand-assets/logo-full.png')
  InstallationConfig.find_or_create_by!(name: 'LOGO_DARK').update!(value: '/brand-assets/logo-full-dark.png')
  InstallationConfig.find_or_create_by!(name: 'LOGO_THUMBNAIL').update!(value: '/brand-assets/logo_thumbnail.png')
  
  # Disable SSO/OAuth
  InstallationConfig.where(name: 'IS_ENTERPRISE').delete_all
  
  Rails.logger.info "✅ CommMate branding applied successfully!"
rescue => e
  Rails.logger.warn "⚠️  Could not apply CommMate branding: #{e.message}"
  Rails.logger.warn "This is normal on first boot before database exists"
end

