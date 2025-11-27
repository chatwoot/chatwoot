class Llm::BaseOpenAiService
  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  attr_reader :model

  def initialize
    Llm::Config.initialize!
    setup_model
  end

  def chat(model: @model)
    RubyLLM.chat(model: model)
  end

  private

  def uri_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
