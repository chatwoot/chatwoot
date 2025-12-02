class Captain::LlmService
  def initialize(config)
    @provider = initialize_provider(config)
  end

  def call(messages, functions = [])
    @provider.chat(messages, functions)
  end

  private

  def initialize_provider(config)
    provider_name = InstallationConfig.find_by(name: 'CAPTAIN_LLM_PROVIDER')&.value || 'openai'
    config[:api_key] = InstallationConfig.find_by(name: 'CAPTAIN_LLM_API_KEY')&.value
    config[:model] = InstallationConfig.find_by(name: 'CAPTAIN_LLM_MODEL')&.value

    case provider_name
    when 'gemini'
      Captain::Llm::Providers::Gemini.new(config)
    else
      # Default to OpenAI
      Captain::Llm::Providers::Openai.new(config)
    end
  end
end
