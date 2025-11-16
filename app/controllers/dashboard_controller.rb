class DashboardController < ActionController::Base
  include SwitchLocale

  before_action :set_application_pack
  before_action :set_global_config
  before_action :set_dashboard_scripts
  around_action :switch_locale
  before_action :ensure_installation_onboarding, only: [:index]
  before_action :render_hc_if_custom_domain, only: [:index]
  before_action :ensure_html_format
  layout 'vueapp'

  def index; end

  private

  def ensure_html_format
    render json: { error: 'Please use API routes instead of dashboard routes for JSON requests' }, status: :not_acceptable if request.format.json?
  end

  def set_global_config
    @global_config = GlobalConfig.get(
      'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
      'INSTALLATION_NAME',
      'WIDGET_BRAND_URL', 'TERMS_URL',
      'BRAND_URL', 'BRAND_NAME',
      'PRIVACY_URL',
      'DISPLAY_MANIFEST',
      'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
      'CHATWOOT_INBOX_TOKEN',
      'API_CHANNEL_NAME',
      'API_CHANNEL_THUMBNAIL',
      'ANALYTICS_TOKEN',
      'DIRECT_UPLOADS_ENABLED',
      'HCAPTCHA_SITE_KEY',
      'LOGOUT_REDIRECT_LINK',
      'DISABLE_USER_PROFILE_UPDATE',
      'DEPLOYMENT_ENV',
      'INSTALLATION_PRICING_PLAN'
    ).merge(app_config)
  end

  def set_dashboard_scripts
    @dashboard_scripts = sensitive_path? ? nil : GlobalConfig.get_value('DASHBOARD_SCRIPTS')
  end

  def ensure_installation_onboarding
    redirect_to '/installation/onboarding' if ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end

  def render_hc_if_custom_domain
    domain = request.host
    return if domain == URI.parse(ENV.fetch('FRONTEND_URL', '')).host

    @portal = Portal.find_by(custom_domain: domain)
    return unless @portal

    @locale = @portal.default_locale
    render 'public/api/v1/portals/show', layout: 'portal', portal: @portal and return
  end

  def app_config
    {
      APP_VERSION: Chatwoot.config[:version],
      VAPID_PUBLIC_KEY: VapidService.public_key,
      ENABLE_ACCOUNT_SIGNUP: GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'true'),
      FB_APP_ID: GlobalConfigService.load('FB_APP_ID', ''),
      INSTAGRAM_APP_ID: GlobalConfigService.load('INSTAGRAM_APP_ID', ''),
      FACEBOOK_API_VERSION: GlobalConfigService.load('FACEBOOK_API_VERSION', 'v23.0'),
      WHATSAPP_APP_ID: whatsapp_app_id,
      WHATSAPP_CONFIGURATION_ID: whatsapp_configuration_id,
      WHATSAPP_API_VERSION: whatsapp_api_version,
      IS_ENTERPRISE: ChatwootApp.enterprise?,
      AZURE_APP_ID: GlobalConfigService.load('AZURE_APP_ID', ''),
      GOOGLE_OAUTH_CLIENT_ID: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', ''),
      FRONTEND_URL: ENV.fetch('FRONTEND_URL', ''),
      GIT_SHA: GIT_HASH
    }
  end

  def set_application_pack
    @application_pack = if request.path.include?('/auth') || request.path.include?('/login')
                          'v3app'
                        else
                          'dashboard'
                        end
  end

  def sensitive_path?
    # dont load dashboard scripts on sensitive paths like password reset
    sensitive_paths = [edit_user_password_path].freeze

    # remove app prefix
    current_path = request.path.gsub(%r{^/app}, '')

    sensitive_paths.include?(current_path)
  end

  def whatsapp_app_id
    account = current_user&.account
    account_settings = account&.whatsapp_settings
    app_id = account_settings&.app_id.presence || GlobalConfigService.load('WHATSAPP_APP_ID', '')

    Rails.logger.info "[DASHBOARD_CONFIG] 👤 User: #{current_user&.email}, Account: #{account&.name} (ID: #{account&.id})"
    Rails.logger.info "[DASHBOARD_CONFIG] WhatsApp App ID - Account Settings: #{account_settings&.app_id.present? ? '✓' : '✗'}, Using: #{app_id.present? ? app_id[0..8] : 'NONE'}"
    app_id
  end

  def whatsapp_configuration_id
    account_settings = current_user&.account&.whatsapp_settings
    config_id = account_settings&.configuration_id.presence || GlobalConfigService.load('WHATSAPP_CONFIGURATION_ID', '')

    Rails.logger.info "[DASHBOARD_CONFIG] WhatsApp Configuration ID - Account Settings: #{account_settings&.configuration_id.present? ? '✓' : '✗'}, Using: #{config_id}"
    config_id
  end

  def whatsapp_api_version
    account_settings = current_user&.account&.whatsapp_settings
    api_version = account_settings&.api_version.presence || GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')

    Rails.logger.info "[DASHBOARD_CONFIG] WhatsApp API Version - Account Settings: #{account_settings&.api_version.present? ? '✓' : '✗'}, Using: #{api_version}"
    api_version
  end
end
