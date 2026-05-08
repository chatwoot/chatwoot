class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
  CONFIG_MAPPING = {
    'facebook' => %w[
      FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET IG_VERIFY_TOKEN FACEBOOK_API_VERSION ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT
    ],
    'shopify' => %w[SHOPIFY_CLIENT_ID SHOPIFY_CLIENT_SECRET],
    'microsoft' => %w[AZURE_APP_ID AZURE_APP_SECRET],
    'email' => %w[MAILER_INBOUND_EMAIL_DOMAIN ACCOUNT_EMAILS_LIMIT ACCOUNT_EMAILS_PLAN_LIMITS],
    'linear' => %w[LINEAR_CLIENT_ID LINEAR_CLIENT_SECRET],
    'slack' => %w[SLACK_CLIENT_ID SLACK_CLIENT_SECRET],
    'instagram' => %w[
      INSTAGRAM_APP_ID INSTAGRAM_APP_SECRET INSTAGRAM_VERIFY_TOKEN INSTAGRAM_API_VERSION ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT
    ],
    'tiktok' => %w[TIKTOK_APP_ID TIKTOK_APP_SECRET TIKTOK_API_VERSION],
    'whatsapp_embedded' => %w[WHATSAPP_APP_ID WHATSAPP_APP_SECRET WHATSAPP_CONFIGURATION_ID WHATSAPP_API_VERSION],
    'notion' => %w[NOTION_CLIENT_ID NOTION_CLIENT_SECRET],
    'google' => %w[GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET GOOGLE_OAUTH_REDIRECT_URI ENABLE_GOOGLE_OAUTH_LOGIN],
    'captain' => %w[CAPTAIN_OPEN_AI_API_KEY CAPTAIN_OPEN_AI_MODEL CAPTAIN_OPEN_AI_ENDPOINT],
    'branding' => %w[
      INSTALLATION_NAME
      BRAND_NAME
      BRAND_URL
      WIDGET_BRAND_URL
      LOGO
      LOGO_DARK
      LOGO_THUMBNAIL
      BRAND_PRIMARY_COLOR
      BRAND_PRIMARY_HOVER_COLOR
      BRAND_SECONDARY_COLOR
      TERMS_URL
      PRIVACY_URL
      DISPLAY_MANIFEST
    ]
  }.freeze

  DEFAULT_CONFIGS = %w[
    ENABLE_ACCOUNT_SIGNUP
    FIREBASE_PROJECT_ID
    FIREBASE_CREDENTIALS
    WEBHOOK_TIMEOUT
    MAXIMUM_FILE_UPLOAD_SIZE
    WIDGET_TOKEN_EXPIRY
  ].freeze

  before_action :set_config
  before_action :allowed_configs
  def show
    @installation_configs = ConfigLoader.new.general_configs.each_with_object({}) do |config_hash, result|
      result[config_hash['name']] = config_hash.except('name')
    end

    # ref: https://github.com/rubocop/rubocop/issues/7767
    # rubocop:disable Style/HashTransformValues
    saved_config = InstallationConfig.where(name: @allowed_configs)
                                     .pluck(:name, :serialized_value)
                                     .map { |name, serialized_value| [name, serialized_value['value']] }
                                     .to_h
    # rubocop:enable Style/HashTransformValues

    default_config = @allowed_configs.index_with { |key| @installation_configs[key]&.dig('value') }
    @app_config = default_config.merge(saved_config)
  end

  def create
    errors = []
    params.fetch('app_config', {}).each do |key, value|
      next unless @allowed_configs.include?(key)

      i = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
      i.value = uploaded_asset_path(key, i) || value
      errors.concat(i.errors.full_messages) unless i.save
    end

    if errors.any?
      redirect_to super_admin_app_config_path(config: @config), alert: errors.join(', ')
    else
      redirect_to super_admin_settings_path, notice: "App Configs - #{@config.titleize} updated successfully"
    end
  end

  private

  def set_config
    @config = params[:config] || 'general'
  end

  def allowed_configs
    @allowed_configs = CONFIG_MAPPING.fetch(@config, DEFAULT_CONFIGS)
  end

  def uploaded_asset_path(key, installation_config)
    uploaded_file = params.dig('app_config_files', key)
    return if uploaded_file.blank?

    installation_config.asset.attach(uploaded_file)
    rails_blob_path(installation_config.asset, only_path: true)
  end
end

SuperAdmin::AppConfigsController.prepend_mod_with('SuperAdmin::AppConfigsController')
