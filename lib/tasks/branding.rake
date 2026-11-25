# NOTE: See https://github.com/fazer-ai/chatwoot/blob/main/CUSTOM_BRANDING.md for more details.
namespace :branding do
  desc 'Updates branding configurations from environment variables or defaults'
  task update: :environment do
    configurable_items = {
      # The installation wide name that would be used in the dashboard, title etc.
      'INSTALLATION_NAME' => 'Chatwoot',
      # The thumbnail that would be used for favicon (512px X 512px)
      'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.svg',
      # The logo that would be used on the dashboard, login page etc.
      'LOGO' => '/brand-assets/logo.svg',
      # The logo that would be used on the dashboard, login page etc. for dark mode
      'LOGO_DARK' => '/brand-assets/logo_dark.svg',
      # The logo shown at the top of outgoing emails (PNG or JPG; email clients do not render SVG)
      'LOGO_EMAIL' => '',
      # The URL that would be used in emails under the section “Powered By”
      'BRAND_URL' => 'https://www.chatwoot.com',
      # The URL that would be used in the widget under the section “Powered By”
      'WIDGET_BRAND_URL' => 'https://www.chatwoot.com',
      # The name that would be used in emails and the widget
      'BRAND_NAME' => 'Chatwoot',
      # Hex colour used in emails and for the PWA theme (example: #1f93ff)
      'BRAND_COLOR' => '#1f93ff',
      # The terms of service URL displayed in Signup Page
      'TERMS_URL' => 'https://www.chatwoot.com/terms-of-service',
      # The privacy policy URL displayed in the app
      'PRIVACY_URL' => 'https://www.chatwoot.com/privacy-policy',
      # Display default Chatwoot metadata like favicons and upgrade warnings
      'DISPLAY_MANIFEST' => true
    }

    # The environment seeds the brand until the super admin's Branding page is saved; from then
    # on the page owns it and this task leaves it as it is. BRANDING_FORCE=true writes every key
    # from the environment again and hands the brand back to it.
    edited = InstallationConfig.find_by(name: 'BRANDING_EDITED_IN_SUPER_ADMIN')
    next puts('Kept the branding saved in the super admin.') if edited&.value.present? && ENV['BRANDING_FORCE'] != 'true'

    configurable_items.each do |config_name, default_value|
      value = if default_value.in?([true, false])
                ENV.fetch(config_name, default_value.to_s) == 'true'
              else
                ENV.fetch(config_name, default_value)
              end

      InstallationConfig.find_by!(name: config_name).update!(value: value)
      puts "Updated '#{config_name}' to '#{value}'."
    end

    edited&.destroy!
    puts 'Branding configuration update finished.'
  end
end
