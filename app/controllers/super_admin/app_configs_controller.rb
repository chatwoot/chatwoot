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
    populate_captain_provider_options if @config == 'captain'
    apply_captain_defaults if @config == 'captain'
    apply_captain_api_base_options if @config == 'captain'
  end

  def create
    errors = captain_config_errors(params.fetch('app_config', {}))
    errors = save_app_configs if errors.blank?

    if errors.any?
      redirect_to super_admin_app_config_path(config: @config), alert: errors.join(', ')
    else
      redirect_to super_admin_settings_path, flash: success_flash
    end
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
      'email' => %w[MAILER_INBOUND_EMAIL_DOMAIN ACCOUNT_EMAILS_LIMIT ACCOUNT_EMAILS_PLAN_LIMITS],
      'linear' => %w[LINEAR_CLIENT_ID LINEAR_CLIENT_SECRET],
      'slack' => %w[SLACK_CLIENT_ID SLACK_CLIENT_SECRET],
      'instagram' => %w[INSTAGRAM_APP_ID INSTAGRAM_APP_SECRET INSTAGRAM_VERIFY_TOKEN INSTAGRAM_API_VERSION ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT],
      'tiktok' => %w[TIKTOK_APP_ID TIKTOK_APP_SECRET TIKTOK_API_VERSION],
      'whatsapp_embedded' => %w[WHATSAPP_APP_ID WHATSAPP_APP_SECRET WHATSAPP_CONFIGURATION_ID WHATSAPP_API_VERSION],
      'notion' => %w[NOTION_CLIENT_ID NOTION_CLIENT_SECRET],
      'google' => %w[GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET GOOGLE_OAUTH_REDIRECT_URI ENABLE_GOOGLE_OAUTH_LOGIN],
      'captain' => captain_config_options
    }

    @allowed_configs = mapping.fetch(
      @config,
      %w[ENABLE_ACCOUNT_SIGNUP FIREBASE_PROJECT_ID FIREBASE_CREDENTIALS WEBHOOK_TIMEOUT MAXIMUM_FILE_UPLOAD_SIZE WIDGET_TOKEN_EXPIRY]
    )
  end

  def success_notice
    message = "#{@config.titleize} settings updated successfully"
    return message unless restart_required_config_saved?

    "#{message.delete_suffix('.')}. Restart Chatwoot web and worker processes to apply this change everywhere."
  end

  def success_flash
    restart_required_config_saved? ? { success: success_notice } : { notice: success_notice }
  end

  def restart_required_config_saved?
    params.fetch('app_config', {}).keys.intersect?(InstallationConfig::RESTART_REQUIRED_CONFIG_KEYS)
  end

  def captain_config_options
    %w[
      CAPTAIN_OPEN_AI_API_KEY
      CAPTAIN_AZURE_AI_AUTH_TOKEN
      CAPTAIN_LLM_PROVIDER
      CAPTAIN_OPEN_AI_MODEL
      CAPTAIN_OPEN_AI_ENDPOINT
      CAPTAIN_EMBEDDING_API_KEY
      CAPTAIN_EMBEDDING_MODEL
    ]
  end

  def populate_captain_provider_options
    @installation_configs['CAPTAIN_LLM_PROVIDER']['options'] = Llm::Config.provider_options if @installation_configs['CAPTAIN_LLM_PROVIDER']
  end

  def apply_captain_defaults
    provider = @app_config['CAPTAIN_LLM_PROVIDER']
    @app_config['CAPTAIN_LLM_PROVIDER'] = Llm::Config::DEFAULT_PROVIDER unless Llm::Config.provider_options.key?(provider)
  end

  def apply_captain_api_base_options
    @captain_provider_api_bases = Llm::Config.provider_api_base_options
    @captain_provider_api_key_requirements = Llm::Config.provider_options.keys.index_with { |provider| Llm::Config.api_key_required?(provider) }
  end

  def normalized_config_value(key, value)
    return value unless @config == 'captain'
    return Llm::Config::DEFAULT_PROVIDER if value.blank? && key == 'CAPTAIN_LLM_PROVIDER'
    return Llm::Config.api_base_for(provider: params.dig('app_config', 'CAPTAIN_LLM_PROVIDER'), endpoint: value) if key == 'CAPTAIN_OPEN_AI_ENDPOINT'

    value
  end

  def save_app_configs
    params.fetch('app_config', {}).to_unsafe_h.each_with_object([]) do |(key, value), errors|
      next unless @allowed_configs.include?(key)

      value = normalized_config_value(key, value)
      installation_config = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
      installation_config.value = value
      errors.concat(installation_config.errors.full_messages) unless installation_config.save
    end
  end

  def captain_config_errors(app_config)
    return [] unless @config == 'captain'

    provider = normalized_config_value('CAPTAIN_LLM_PROVIDER', app_config['CAPTAIN_LLM_PROVIDER'])
    endpoint = normalized_config_value('CAPTAIN_OPEN_AI_ENDPOINT', app_config['CAPTAIN_OPEN_AI_ENDPOINT'])

    return ['Provider is not supported'] unless provider_supported?(provider)

    [
      model_config_error(provider, endpoint, app_config),
      api_key_config_error(provider, endpoint, app_config),
      api_base_config_error(provider, app_config)
    ].compact
  end

  def captain_model_required?(provider, endpoint)
    !Llm::Config.direct_openai_endpoint?(provider: provider, endpoint: endpoint)
  end

  def model_required_message
    'Model is required unless Provider is OpenAI with API Base blank/default'
  end

  def model_config_error(provider, endpoint, app_config)
    model_required_message if captain_model_required?(provider, endpoint) && app_config['CAPTAIN_OPEN_AI_MODEL'].blank?
  end

  def api_key_config_error(provider, endpoint, app_config)
    credential_required_message(provider) if captain_credential_required?(provider, endpoint, app_config)
  end

  def api_base_config_error(provider, app_config)
    api_base_required_message(provider) if api_base_required?(provider) && app_config['CAPTAIN_OPEN_AI_ENDPOINT'].blank?
  end

  def provider_supported?(provider)
    Llm::Config.provider_options.key?(provider)
  end

  def api_base_required?(provider)
    Llm::Config.provider_api_base_options[provider].blank?
  end

  def api_base_required_message(_provider)
    'API Base is required for the selected Provider'
  end

  def captain_credential_required?(provider, endpoint, app_config)
    return false unless Llm::Config.api_key_required?(provider)
    return false if Llm::Config.direct_openai_endpoint?(provider: provider, endpoint: endpoint)

    return app_config['CAPTAIN_OPEN_AI_API_KEY'].blank? && app_config['CAPTAIN_AZURE_AI_AUTH_TOKEN'].blank? if provider == Llm::Config::AZURE_PROVIDER

    app_config['CAPTAIN_OPEN_AI_API_KEY'].blank?
  end

  def credential_required_message(provider)
    return 'API Key or Azure AI Auth Token is required for Azure' if provider == Llm::Config::AZURE_PROVIDER

    'API Key is required for the selected Provider'
  end
end

SuperAdmin::AppConfigsController.prepend_mod_with('SuperAdmin::AppConfigsController')
