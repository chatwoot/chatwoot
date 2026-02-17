# frozen_string_literal: true

# Base service for LLM operations using RubyLLM.
# Supports multiple providers (OpenAI, Gemini, DeepSeek) via CAPTAIN_AI_PROVIDER config.
class Llm::BaseAiService
  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  DEFAULT_TEMPERATURE = 1.0

  MODEL_CONFIG_KEYS = {
    'openai' => 'CAPTAIN_OPEN_AI_MODEL',
    'gemini' => 'CAPTAIN_GEMINI_MODEL',
    'deepseek' => 'CAPTAIN_DEEPSEEK_MODEL'
  }.freeze

  attr_reader :model, :temperature

  def initialize
    Llm::Config.initialize!
    setup_model
    setup_temperature
  end

  def chat(model: @model, temperature: @temperature)
    RubyLLM.chat(model: model).with_temperature(temperature)
  end

  private

  def setup_model
    provider = Llm::Config.provider
    config_key = MODEL_CONFIG_KEYS[provider] || 'CAPTAIN_OPEN_AI_MODEL'
    config_value = InstallationConfig.find_by(name: config_key)&.value
    @model = (config_value.presence || Llm::Config.default_model_for_provider)
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end
end
