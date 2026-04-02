class SetConversoBrandUrlsInInstallationConfig < ActiveRecord::Migration[7.1]
  # Matches config/installation_config.yml branding for Converso deployments.
  CONVERSO_BASE = 'https://converso.cybroscloud.com'.freeze

  # Only replace stock Chatwoot URLs so custom domains stay untouched.
  URL_UPDATES = {
    'BRAND_URL' => {
      'https://www.chatwoot.com' => CONVERSO_BASE,
      'http://www.chatwoot.com' => CONVERSO_BASE
    },
    'WIDGET_BRAND_URL' => {
      'https://www.chatwoot.com' => CONVERSO_BASE,
      'http://www.chatwoot.com' => CONVERSO_BASE
    },
    'TERMS_URL' => {
      'https://www.chatwoot.com/terms-of-service' => "#{CONVERSO_BASE}/terms-of-service",
      'http://www.chatwoot.com/terms-of-service' => "#{CONVERSO_BASE}/terms-of-service"
    },
    'PRIVACY_URL' => {
      'https://www.chatwoot.com/privacy-policy' => "#{CONVERSO_BASE}/privacy-policy",
      'http://www.chatwoot.com/privacy-policy' => "#{CONVERSO_BASE}/privacy-policy"
    }
  }.freeze

  def up
    URL_UPDATES.each do |config_name, replacements|
      config = InstallationConfig.find_by(name: config_name)
      next unless config

      current = config.value.to_s
      new_value = replacements[current]
      next unless new_value

      config.update!(value: new_value)
    end

    GlobalConfig.clear_cache
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
