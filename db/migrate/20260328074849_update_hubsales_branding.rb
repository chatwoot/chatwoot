# frozen_string_literal: true

class UpdateHubsalesBranding < ActiveRecord::Migration[7.0]
  def up
    # Update installation name and branding
    update_config('INSTALLATION_NAME', 'HubSales')
    update_config('BRAND_NAME', 'HubSales')
    update_config('BRAND_URL', 'https://adhubmarketing.com.br')
    update_config('WIDGET_BRAND_URL', 'https://adhubmarketing.com.br')

    # Update logo paths to use PNG instead of SVG
    update_config('LOGO', '/brand-assets/logo.png')
    update_config('LOGO_DARK', '/brand-assets/logo_dark.png')
    update_config('LOGO_THUMBNAIL', '/brand-assets/logo_thumbnail.png')
  end

  def down
    # Revert to Chatwoot branding
    update_config('INSTALLATION_NAME', 'Chatwoot')
    update_config('BRAND_NAME', 'Chatwoot')
    update_config('BRAND_URL', 'https://www.chatwoot.com')
    update_config('WIDGET_BRAND_URL', 'https://www.chatwoot.com')

    # Revert logo paths to SVG
    update_config('LOGO', '/brand-assets/logo.svg')
    update_config('LOGO_DARK', '/brand-assets/logo_dark.svg')
    update_config('LOGO_THUMBNAIL', '/brand-assets/logo_thumbnail.svg')
  end

  private

  def update_config(name, value)
    config = InstallationConfig.find_or_initialize_by(name: name)
    config.value = value
    config.save!
  end
end
