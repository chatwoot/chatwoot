class Instagram::LoginConfiguration
  def self.login_method
    GlobalConfigService.load('INSTAGRAM_LOGIN_METHOD', nil).presence || 'instagram_login'
  end

  def self.configuration_id
    return unless login_method == 'unified_login'

    configuration_id = GlobalConfigService.load('INSTAGRAM_CONFIGURATION_ID', nil)
    raise Instagram::UnifiedLoginService::Error, I18n.t('instagram.missing_credentials') if configuration_id.blank?

    configuration_id
  end

  def self.app_id
    key = login_method == 'unified_login' ? 'INSTAGRAM_UNIFIED_APP_ID' : 'INSTAGRAM_APP_ID'
    GlobalConfigService.load(key, '')
  end
end
