class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
  before_action :set_config
  before_action :allowed_configs
  def show
    # ref: https://github.com/rubocop/rubocop/issues/7767
    # rubocop:disable Style/HashTransformValues
    @app_config = InstallationConfig.where(name: @allowed_configs)
                                    .pluck(:name, :serialized_value)
                                    .map { |name, serialized_value| [name, serialized_value['value']] }
                                    .to_h
    # rubocop:enable Style/HashTransformValues
    @installation_configs = ConfigLoader.new.general_configs.each_with_object({}) do |config_hash, result|
      result[config_hash['name']] = config_hash.except('name')
    end
  end

  def create
    params['app_config'].each do |key, value|
      next unless @allowed_configs.include?(key)

      i = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
      i.value = value
      i.save!
    end
    redirect_to super_admin_settings_path, notice: "App Configs - #{@config.titleize} updated successfully"
  end

  private

  def set_config
    @config = params[:config] || 'general'
  end

  def allowed_configs
    mapping = {
      'facebook' => %w[FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET IG_VERIFY_TOKEN FACEBOOK_API_VERSION ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT],
      'shopify' => %w[SHOPIFY_CLIENT_ID SHOPIFY_CLIENT_SECRET],
      'microsoft' => %w[AZURE_APP_ID AZURE_APP_SECRET],
      'email' => %w[MAILER_INBOUND_EMAIL_DOMAIN SMTP_ADDRESS SMTP_PORT SMTP_USERNAME SMTP_PASSWORD],
      'linear' => %w[LINEAR_CLIENT_ID LINEAR_CLIENT_SECRET],
      'slack' => %w[SLACK_CLIENT_ID SLACK_CLIENT_SECRET],
      'notion' => %w[NOTION_CLIENT_ID NOTION_CLIENT_SECRET],
      'instagram' => %w[INSTAGRAM_APP_ID INSTAGRAM_APP_SECRET INSTAGRAM_VERIFY_TOKEN INSTAGRAM_API_VERSION ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT],
      'whatsapp' => %w[WHATSAPP_WEBHOOK_VERIFY_TOKEN WHATSAPP_ACCESS_TOKEN WHATSAPP_PHONE_NUMBER_ID WHATSAPP_BUSINESS_ACCOUNT_ID],
      'telegram' => %w[TELEGRAM_BOT_TOKEN TELEGRAM_WEBHOOK_URL],
      'sms' => %w[SMS_PROVIDER SMS_API_KEY SMS_FROM_NUMBER TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN],
      'agent_capacity' => %w[DEFAULT_MAX_ASSIGNMENT_LIMIT ENABLE_AGENT_CAPACITY_LIMITS],
      'captain' => %w[CAPTAIN_API_KEY CAPTAIN_MODEL CAPTAIN_TEMPERATURE CAPTAIN_MAX_TOKENS],
      'custom_branding' => %w[BRAND_NAME BRAND_LOGO_URL BRAND_PRIMARY_COLOR BRAND_SECONDARY_COLOR HIDE_CHATWOOT_BRANDING]
    }

    @allowed_configs = mapping.fetch(@config, %w[ENABLE_ACCOUNT_SIGNUP FIREBASE_PROJECT_ID FIREBASE_CREDENTIALS])
  end
end

SuperAdmin::AppConfigsController.prepend_mod_with('SuperAdmin::AppConfigsController')
