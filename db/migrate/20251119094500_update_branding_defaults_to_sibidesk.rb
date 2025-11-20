class UpdateBrandingDefaultsTodoozadesk < ActiveRecord::Migration[7.0]
  BRANDING_OVERRIDES = {
    'INSTALLATION_NAME' => 'Dooza Desk',
    'BRAND_NAME' => 'Dooza Desk',
    'BRAND_URL' => 'https://www.doozadesk.com',
    'WIDGET_BRAND_URL' => 'https://www.doozadesk.com',
    'TERMS_URL' => 'https://www.doozadesk.com/terms-of-service',
    'PRIVACY_URL' => 'https://www.doozadesk.com/privacy-policy'
  }.freeze

  LEGACY_DEFAULTS = {
    'INSTALLATION_NAME' => 'Chatwoot',
    'BRAND_NAME' => 'Chatwoot',
    'BRAND_URL' => 'https://www.chatwoot.com',
    'WIDGET_BRAND_URL' => 'https://www.chatwoot.com',
    'TERMS_URL' => 'https://www.chatwoot.com/terms-of-service',
    'PRIVACY_URL' => 'https://www.chatwoot.com/privacy-policy'
  }.freeze

  def up
    BRANDING_OVERRIDES.each do |name, new_value|
      update_installation_config(name, new_value) do |current|
        current.blank? || current == LEGACY_DEFAULTS[name]
      end
    end

    GlobalConfig.clear_cache
  end

  def down
    LEGACY_DEFAULTS.each do |name, legacy_value|
      update_installation_config(name, legacy_value) do |current|
        current.blank? || current == BRANDING_OVERRIDES[name]
      end
    end

    GlobalConfig.clear_cache
  end

  private

  def update_installation_config(name, new_value)
    record = InstallationConfig.find_by(name: name)
    return unless record

    current_value = record.value.presence
    return unless yield(current_value)

    record.update!(value: new_value)
  end
end
