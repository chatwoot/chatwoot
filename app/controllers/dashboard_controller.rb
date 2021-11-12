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
      SMTP_OPENSSL_VERIFY_MODE: GlobalConfigService.load('SMTP_OPENSSL_VERIFY_MODE','peer'),
      MAILER_INBOUND_EMAIL_DOMAIN: GlobalConfigService.load('MAILER_INBOUND_EMAIL_DOMAIN',''),
      RAILS_INBOUND_EMAIL_SERVICE: GlobalConfigService.load('RAILS_INBOUND_EMAIL_SERVICE',''),
      RAILS_INBOUND_EMAIL_PASSWORD: GlobalConfigService.load('RAILS_INBOUND_EMAIL_PASSWORD',''),
      MAILGUN_INGRESS_SIGNING_KEY: GlobalConfigService.load('MAILGUN_INGRESS_SIGNING_KEY',''),
      MANDRILL_INGRESS_API_KEY: GlobalConfigService.load('MANDRILL_INGRESS_API_KEY',''),
      ACTIVE_STORAGE_SERVICE: GlobalConfigService.load('ACTIVE_STORAGE_SERVICE','local'),
      S3_BUCKET_NAME: GlobalConfigService.load('S3_BUCKET_NAME',''),
      AWS_ACCESS_KEY_ID: GlobalConfigService.load('AWS_ACCESS_KEY_ID',''),
      AWS_SECRET_ACCESS_KEY: GlobalConfigService.load('AWS_SECRET_ACCESS_KEY',''),
      AWS_REGION: GlobalConfigService.load('AWS_REGION',''),
      FB_VERIFY_TOKEN: GlobalConfigService.load('FB_VERIFY_TOKEN',''),
      FB_APP_SECRET: GlobalConfigService.load('FB_APP_SECRET',''),
      FB_APP_ID: GlobalConfigService.load('FB_APP_ID',''),
      TWITTER_APP_ID: GlobalConfigService.load('TWITTER_APP_ID',''),
      TWITTER_CONSUMER_KEY: GlobalConfigService.load('TWITTER_CONSUMER_KEY',''),
      TWITTER_CONSUMER_SECRET: GlobalConfigService.load('TWITTER_CONSUMER_SECRET',''),
      TWITTER_ENVIRONMENT: GlobalConfigService.load('TWITTER_ENVIRONMENT',''),
      SLACK_CLIENT_ID: GlobalConfigService.load('SLACK_CLIENT_ID',''),
      SLACK_CLIENT_SECRET: GlobalConfigService.load('SLACK_CLIENT_SECRET',''),
      IOS_APP_ID: GlobalConfigService.load('IOS_APP_ID','6C953F3RX2.com.chatwoot.app'),
      IOS_APP_IDENTIFIER: GlobalConfigService.load('IOS_APP_IDENTIFIER','1495796682'),
      ANDROID_BUNDLE_ID: GlobalConfigService.load('ANDROID_BUNDLE_ID','com.chatwoot.app'),
      ANDROID_SHA256_CERT_FINGERPRINT: GlobalConfigService.load('ANDROID_SHA256_CERT_FINGERPRINT','AC:73:8E:DE:EB:56:EA:CC:10:87:02:A7:65:37:7B:38:D4:5D:D4:53:F8:3B:FB:D3:C6:28:64:1D:AA:08:1E:D8')
    )
  end

  def ensure_installation_onboarding
    redirect_to '/installation/onboarding' if ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end
end
