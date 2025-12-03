class Captain::LlmService
  def initialize(config)
    @provider = initialize_provider(config)
  end

  def call(messages, functions = [])
    @provider.chat(messages, functions)
  end

  private

  def initialize_provider(config)
    config[:api_key] = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    config[:model] = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value

    Captain::Llm::Providers::Openai.new(config)
  end
end
