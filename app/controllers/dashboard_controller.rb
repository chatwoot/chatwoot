class DashboardController < ActionController::Base
  include SwitchLocale

  before_action :set_global_config
  around_action :switch_locale
  before_action :ensure_installation_onboarding, only: [:index]

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
      'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
      'CHATWOOT_INBOX_TOKEN',
      'API_CHANNEL_NAME',
      'API_CHANNEL_THUMBNAIL',
      'ANALYTICS_TOKEN',
      'ANALYTICS_HOST'
    ).merge(
      APP_VERSION: Chatwoot.config[:version],
      VAPID_PUBLIC_KEY: VapidService.public_key,
      ENABLE_ACCOUNT_SIGNUP: GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false'),
      MAILER_SENDER_EMAIL: GlobalConfigService.load('MAILER_SENDER_EMAIL','Chatwoot <accounts@chatwoot.com>'),
      SMTP_DOMAIN: GlobalConfigService.load('SMTP_DOMAIN','chatwoot.com'),
      SMTP_PORT: GlobalConfigService.load('SMTP_PORT','1025'),
      SMTP_USERNAME: GlobalConfigService.load('SMTP_USERNAME',''),
      SMTP_PASSWORD: GlobalConfigService.load('SMTP_PASSWORD',''),
      SMTP_AUTHENTICATION: GlobalConfigService.load('SMTP_AUTHENTICATION',''),
      SMTP_ENABLE_STARTTLS_AUTO: GlobalConfigService.load('SMTP_ENABLE_STARTTLS_AUTO','true'),
      SMTP_OPENSSL_VERIFY_MODE: GlobalConfigService.load('SMTP_OPENSSL_VERIFY_MODE','peer')
    )
  end

  def ensure_installation_onboarding
    redirect_to '/installation/onboarding' if ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end
end
