class DashboardController < ActionController::Base
  before_action :set_global_config

  layout 'vueapp'

  def index; end

  private

  def set_global_config
    @global_config = GlobalConfig.get(
      'LOGO',
      'LOGO_THUMBNAIL',
      'INSTALLATION_NAME',
      'WIDGET_BRAND_URL',
      'TERMS_URL',
      'PRIVACY_URL',
      'DISPLAY_MANIFEST',
      'CREATE_NEW_ACCOUNT_FROM_DASHBOARD'
    ).merge(
      APP_VERSION: Chatwoot.config[:version]
    )
  end
end
