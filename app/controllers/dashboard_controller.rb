class DashboardController < ActionController::Base
  include SwitchLocale
  include PortalHomeData

  GLOBAL_CONFIG_KEYS = %w[
    LOGO
    LOGO_DARK
    LOGO_THUMBNAIL
    INSTALLATION_NAME
    WIDGET_BRAND_URL
    TERMS_URL
    BRAND_URL
    BRAND_NAME
    PRIVACY_URL
    DISPLAY_MANIFEST
    CREATE_NEW_ACCOUNT_FROM_DASHBOARD
    CHATWOOT_INBOX_TOKEN
    API_CHANNEL_NAME
    API_CHANNEL_THUMBNAIL
    CLOUD_ANALYTICS_TOKEN
    DIRECT_UPLOADS_ENABLED
    MAXIMUM_FILE_UPLOAD_SIZE
    HCAPTCHA_SITE_KEY
    LOGOUT_REDIRECT_LINK
    DISABLE_USER_PROFILE_UPDATE
    DISABLE_META_INBOX_CREATION
    DISABLE_META_MESSAGE_SENDING
    DEPLOYMENT_ENV
    INSTALLATION_PRICING_PLAN
  ].freeze

  before_action :set_application_pack
  before_action :set_global_config
  before_action :set_dashboard_scripts
  around_action :switch_locale
  before_action :ensure_installation_onboarding, only: [:index]
  before_action :render_hc_if_custom_domain, only: [:index]
  before_action :process_trusted_proxy_auth, only: [:index]
  before_action :ensure_html_format
  layout 'vueapp'

  def index; end

  private

  def ensure_html_format
    render json: { error: 'Please use API routes instead of dashboard routes for JSON requests' }, status: :not_acceptable if request.format.json?
  end

  def set_global_config
    @global_config = GlobalConfig.get(*GLOBAL_CONFIG_KEYS).merge(app_config)
    # Behind a trusted proxy the default post-logout target (/app/login) would sign the
    # user straight back in, so logout must land on the proxy's own logout endpoint.
    @global_config['LOGOUT_REDIRECT_LINK'] = trusted_proxy_logout_redirect_link if trusted_proxy_auth_enabled?
  end

  def set_dashboard_scripts
    @dashboard_scripts = sensitive_path? ? nil : GlobalConfig.get_value('DASHBOARD_SCRIPTS')
  end

  def ensure_installation_onboarding
    redirect_to '/installation/onboarding' if ::Redis::Alfred.get(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
  end

  # Auto-login for installations running behind a trusted authenticating proxy
  # (e.g. Cloudflare Access sets Cf-Access-Authenticated-User-Email). The proxy is
  # trusted to strip client-supplied values for this header, so its presence alone
  # proves the user's identity; we exchange it for a short-lived SSO auth token that
  # the login page submits automatically.
  def process_trusted_proxy_auth
    return unless request.path == '/app/login'
    return if params[:sso_auth_token].present?
    return unless trusted_proxy_auth_enabled?

    email = request.headers[trusted_proxy_auth_header]
    return if email.blank?

    user = User.from_email(email.strip)
    return if user.blank?

    redirect_to "/app/login?email=#{ERB::Util.url_encode(user.email)}&sso_auth_token=#{user.generate_sso_auth_token}"
  end

  # Plain ENV reads (no InstallationConfig): the env var stays authoritative on every
  # boot instead of being frozen into the DB by the first request that reads it.
  def trusted_proxy_auth_enabled?
    ENV.fetch('ENABLE_TRUSTED_PROXY_AUTH', 'false') == 'true'
  end

  def trusted_proxy_auth_header
    ENV.fetch('TRUSTED_PROXY_AUTH_HEADER', 'Cf-Access-Authenticated-User-Email')
  end

  def trusted_proxy_logout_redirect_link
    ENV.fetch('TRUSTED_PROXY_LOGOUT_REDIRECT_LINK', '/cdn-cgi/access/logout')
  end

  def render_hc_if_custom_domain
    domain = request.host
    return if domain == URI.parse(ENV.fetch('FRONTEND_URL', '')).host

    @portal = Portal.find_by(custom_domain: domain)
    return unless @portal

    @locale = @portal.default_locale
    request.variant = :documentation if @portal.layout == 'documentation'
    load_home_data
    render 'public/api/v1/portals/show', layout: 'portal', portal: @portal and return
  end

  def app_config
    {
      APP_VERSION: Chatwoot.config[:version],
      VAPID_PUBLIC_KEY: VapidService.public_key,
      ENABLE_ACCOUNT_SIGNUP: GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false'),
      FB_APP_ID: GlobalConfigService.load('FB_APP_ID', ''),
      INSTAGRAM_APP_ID: GlobalConfigService.load('INSTAGRAM_APP_ID', ''),
      TIKTOK_APP_ID: GlobalConfigService.load('TIKTOK_APP_ID', ''),
      FACEBOOK_API_VERSION: GlobalConfigService.load('FACEBOOK_API_VERSION', 'v18.0'),
      WHATSAPP_APP_ID: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
      WHATSAPP_CONFIGURATION_ID: GlobalConfigService.load('WHATSAPP_CONFIGURATION_ID', ''),
      IS_ENTERPRISE: ChatwootApp.enterprise?,
      AZURE_APP_ID: GlobalConfigService.load('AZURE_APP_ID', ''),
      GIT_SHA: GIT_HASH,
      ALLOWED_LOGIN_METHODS: allowed_login_methods,
      ACTIVE_PLATFORM_BANNERS: active_platform_banners
    }
  end

  def active_platform_banners
    return [] unless ChatwootApp.chatwoot_cloud?

    PlatformBanner.active.order(created_at: :desc).as_json(only: %i[id banner_message banner_type updated_at])
  end

  def allowed_login_methods
    methods = ['email']
    methods << 'google_oauth' if GlobalConfigService.load('ENABLE_GOOGLE_OAUTH_LOGIN', 'true').to_s != 'false'
    methods << 'saml' if ChatwootHub.pricing_plan != 'community' && GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s != 'false'
    methods
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
