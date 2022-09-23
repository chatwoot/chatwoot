class DashboardController < ActionController::Base
  include SwitchLocale

  before_action :set_global_config
  around_action :switch_locale
  before_action :ensure_installation_onboarding, only: [:index]
  before_action :redirect_to_custom_domain_page
  before_action :redirect_to_saml_login

  layout 'vueapp'

  def index; end

  private

  def set_global_config
    @global_config = GlobalConfig.get(
      'LOGO', 'LOGO_THUMBNAIL',
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
      'ANALYTICS_HOST',
      'DIRECT_UPLOADS_ENABLED',
      'HCAPTCHA_SITE_KEY',
      'LOGOUT_REDIRECT_LINK',
      'DISABLE_USER_PROFILE_UPDATE',
      'DEPLOYMENT_ENV'
    ).merge(app_config)
  end

  def ensure_installation_onboarding
    redirect_to '/installation/onboarding' if ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end

  def redirect_to_custom_domain_page
    custom_domain = request.host
    portal = Portal.find_by(custom_domain: custom_domain)

    return unless portal

    redirect_to "/hc/#{portal.slug}"
  end

  def redirect_to_saml_login
    redirect_to '/saml' and return unless current_user
  end

  def app_config
    {
      APP_VERSION: Chatwoot.config[:version],
      VAPID_PUBLIC_KEY: VapidService.public_key,
      ENABLE_ACCOUNT_SIGNUP: GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false'),
      FB_APP_ID: GlobalConfigService.load('FB_APP_ID', ''),
      FACEBOOK_API_VERSION: 'v14.0',
      IS_ENTERPRISE: ChatwootApp.enterprise?
    }
  end

  def saml_settings
    settings = OneLogin::RubySaml::Settings.new

    settings.assertion_consumer_service_url = "http://#{request.host}/saml/consume"
    settings.sp_entity_id                   = "http://#{request.host}/saml/metadata"
    settings.idp_entity_id                  = 'https://app.onelogin.com/saml/metadata/1835014'
    settings.idp_sso_target_url            = 'https://app.onelogin.com/trust/saml2/http-post/sso/1835014'
    settings.idp_slo_target_url            = 'https://app.onelogin.com/trust/saml2/http-redirect/slo/1835014'
    settings.name_identifier_format = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'

    # Optional for most SAML IdPs
    settings.authn_context = 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport'
    # or as an array
    settings.authn_context = [
      'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport',
      'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'
    ]

    # Optional bindings (defaults to Redirect for logout POST for ACS)
    settings.single_logout_service_binding      = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect' # or :post, :redirect
    settings.assertion_consumer_service_binding = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST' # or :post, :redirect

    settings
  end
end
