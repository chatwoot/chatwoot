class ApplyCommmateBranding < ActiveRecord::Migration[7.1]
  # This migration is idempotent and will always apply CommMate branding
  # Safe to run multiple times - ensures branding consistency on every installation

  def up
    # Skip if InstallationConfig table doesn't exist yet (fresh install)
    return unless ActiveRecord::Base.connection.table_exists?('installation_configs')

    say '🎨 Applying CommMate branding...'

    # Update branding (idempotent - safe to run multiple times)
    update_config('INSTALLATION_NAME', 'CommMate')
    update_config('BRAND_NAME', 'CommMate')

    # Update URLs
    update_config('BRAND_URL', 'https://commmate.com')
    update_config('WIDGET_BRAND_URL', 'https://commmate.com')
    update_config('TERMS_URL', 'https://commmate.com/terms')
    update_config('PRIVACY_URL', 'https://commmate.com/privacy')

    # Update logos
    update_config('LOGO', '/brand-assets/logo-full.png')
    update_config('LOGO_DARK', '/brand-assets/logo-full-dark.png')
    update_config('LOGO_THUMBNAIL', '/brand-assets/logo_thumbnail.png')

    # Disable SSO/OAuth
    InstallationConfig.where(name: 'IS_ENTERPRISE').delete_all

    say '✅ CommMate branding applied successfully!'
  end

  private

  def update_config(name, value)
    config = InstallationConfig.find_or_initialize_by(name: name)
    config.value = value
    config.save!
  end

  def down
    # Intentionally left empty - we want to keep CommMate branding
    say '⚠️  CommMate branding rollback not supported'
  end
end
