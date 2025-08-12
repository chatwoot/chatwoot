class Llm::BaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze

  def initialize
    # FassZap: Use Fabiana AI service factory
    @fabiana_service = Fabiana::AiServiceFactory.create_service
    @provider = Fabiana::AiServiceFactory.get_configured_provider

    # Fallback to direct OpenAI for backward compatibility
    if @fabiana_service.nil?
      @client = OpenAI::Client.new(
        access_token: InstallationConfig.find_by!(name: 'FABIANA_OPEN_AI_API_KEY').value,
        uri_base: uri_base,
        log_errors: Rails.env.development?
      )
      setup_model
    end
  rescue StandardError => e
    Rails.logger.error "Failed to initialize Fabiana AI client: #{e.message}"
    # Fallback to legacy configuration
    initialize_legacy_client
  end

  def chat(parameters:)
    if @fabiana_service
      # Use new Fabiana service
      messages = parameters[:messages]
      functions = parameters[:tools] || []
      @fabiana_service.generate_response(messages, functions)
    else
      # Fallback to legacy OpenAI client
      @client.chat(parameters: parameters)
    end
  end

  private

  def initialize_legacy_client
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'FABIANA_OPEN_AI_API_KEY').value ||
                   InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
  end

  def uri_base
    # Try Fabiana config first, then fallback to Captain config
    endpoint = InstallationConfig.find_by(name: 'FABIANA_OPEN_AI_ENDPOINT')&.value ||
               InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def setup_model
    # Try Fabiana config first, then fallback to Captain config
    config_value = InstallationConfig.find_by(name: 'FABIANA_OPEN_AI_MODEL')&.value ||
                   InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
