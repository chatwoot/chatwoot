class DashboardController < ActionController::Base
  include SwitchLocale

  before_action :set_application_pack
  before_action :set_global_config
  before_action :set_dashboard_scripts
  around_action :switch_locale
  before_action :ensure_installation_onboarding, only: [:index]
  before_action :render_hc_if_custom_domain, only: [:index]

  layout 'vueapp'

  def index; end

  private

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
      'CSML_EDITOR_HOST'
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
      ENABLE_ACCOUNT_SIGNUP: GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false'),
      FB_APP_ID: GlobalConfigService.load('FB_APP_ID', ''),
      FACEBOOK_API_VERSION: GlobalConfigService.load('FACEBOOK_API_VERSION', 'v17.0'),
      IS_ENTERPRISE: ChatwootApp.enterprise?,
      AZURE_APP_ID: GlobalConfigService.load('AZURE_APP_ID', ''),
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
end
