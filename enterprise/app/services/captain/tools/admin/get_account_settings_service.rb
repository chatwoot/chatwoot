class Captain::Tools::Admin::GetAccountSettingsService < Captain::Tools::Admin::BaseTool
  def self.name
    'get_account_settings'
  end

  description 'Get account settings including name, locale, domain, support email, and configuration options'

  def execute
    account_record = account

    <<~RESPONSE.strip
      Account ID: #{account_record.id}
      Name: #{account_record.name}
      Locale: #{account_record.locale}
      Domain: #{account_record.domain}
      Support email: #{account_record.support_email}
      Status: #{account_record.status}
      Settings: #{account_record.settings.to_json}
      Enabled features: #{account_record.enabled_features.join(', ')}
    RESPONSE
  end
end
