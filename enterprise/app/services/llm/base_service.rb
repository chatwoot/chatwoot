class Llm::BaseService
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze

  def initialize
    setup_ruby_llm
    setup_model
  rescue StandardError => e
    raise "Failed to initialize LLM client: #{e.message}"
  end

  private

  def setup_ruby_llm
    api_key = InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value
    ::RubyLLM.configure do |config|
      config.openai_api_key = api_key
    end
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
