class ApplyCommmmateBranding < ActiveRecord::Migration[7.1]
  # This migration is idempotent and will always apply CommMate branding
  # Safe to run multiple times - ensures branding consistency on every installation
  
  def up
    Rails.logger.info "🎨 Applying CommMate branding..."
    
    # Update branding (idempotent - safe to run multiple times)
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
  end

  def down
    # Intentionally left empty - we want to keep CommMate branding
    Rails.logger.warn "⚠️  CommMate branding rollback not supported"
  end
end
