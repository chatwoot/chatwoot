class Api::V1::Accounts::Fabiana::SettingsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Account) }

  def index
    render json: {
      current_provider: current_provider,
      available_providers: available_providers,
      provider_status: provider_status,
      models: available_models
    }
  end

  def update_provider
    provider = params[:provider]
    
    unless Fabiana::AiServiceFactory.available_providers.include?(provider)
      return render json: { error: 'Invalid provider' }, status: :bad_request
    end

    unless Fabiana::AiServiceFactory.provider_configured?(provider)
      return render json: { error: 'Provider not configured' }, status: :bad_request
    end

    config = InstallationConfig.find_or_initialize_by(name: 'FABIANA_AI_PROVIDER')
    config.value = provider
    config.save!

    render json: { 
      message: 'Provider updated successfully',
      current_provider: provider
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def test_provider
    provider = params[:provider] || current_provider
    
    begin
      service = Fabiana::AiServiceFactory.create_service(provider)
      test_messages = [
        { role: 'user', content: 'Hello, this is a test message.' }
      ]
      
      response = service.generate_response(test_messages)
      
      render json: {
        success: true,
        provider: provider,
        response: response[:output],
        model: response[:model]
      }
    rescue StandardError => e
      render json: {
        success: false,
        provider: provider,
        error: e.message
      }, status: :bad_request
    end
  end

  def update_config
    provider = params[:provider]
    config_params = params[:config] || {}

    unless Fabiana::AiServiceFactory.available_providers.include?(provider)
      return render json: { error: 'Invalid provider' }, status: :bad_request
    end

    updated_configs = []

    config_params.each do |key, value|
      config_name = "FABIANA_#{provider.upcase}_#{key.upcase}"
      
      # Validate config name
      unless valid_config_name?(config_name)
        next
      end

      config = InstallationConfig.find_or_initialize_by(name: config_name)
      config.value = value
      config.save!
      
      updated_configs << config_name
    end

    render json: {
      message: 'Configuration updated successfully',
      updated_configs: updated_configs
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def current_provider
    Fabiana::AiServiceFactory.get_configured_provider
  end

  def available_providers
    Fabiana::AiServiceFactory.available_providers.map do |provider|
      {
        name: provider,
        display_name: provider.titleize,
        configured: Fabiana::AiServiceFactory.provider_configured?(provider)
      }
    end
  end

  def provider_status
    Fabiana::AiServiceFactory.get_provider_status
  end

  def available_models
    {
      openai: %w[gpt-4o gpt-4o-mini gpt-4 gpt-3.5-turbo],
      chatgpt: %w[gpt-4 gpt-4-turbo gpt-3.5-turbo],
      groq: Fabiana::GroqService.available_models
    }
  end

  def valid_config_name?(config_name)
    allowed_configs = %w[
      FABIANA_OPENAI_API_KEY
      FABIANA_OPENAI_MODEL
      FABIANA_OPENAI_ENDPOINT
      FABIANA_CHATGPT_API_KEY
      FABIANA_CHATGPT_MODEL
      FABIANA_CHATGPT_ENDPOINT
      FABIANA_GROQ_API_KEY
      FABIANA_GROQ_MODEL
      FABIANA_GROQ_ENDPOINT
    ]
    
    allowed_configs.include?(config_name)
  end
end
