# frozen_string_literal: true

# Base service for LLM operations using RubyLLM.
# New features should inherit from this class.
class Llm::BaseAiService
  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  DEFAULT_TEMPERATURE = 1.0

  attr_reader :model, :temperature

  def initialize
    Llm::Config.initialize!
    setup_provider
    setup_model
    setup_temperature
  end

  def chat(model: @model, temperature: @temperature)
    with_provider_temperature(RubyLLM.chat(model: model, provider: @provider, assume_model_exists: true), temperature)
  end

  private

  # Strips markdown code fences (```json ... ``` or ``` ... ```) that some
  # LLM providers/gateways wrap around JSON responses despite response_format hints.
  def sanitize_json_response(response)
    return response if response.nil?

    response.strip.sub(/\A```(?:\w*)\s*\n?/, '').sub(/\n?\s*```\s*\z/, '').strip
  end

  def with_json_response_format(chat, **params)
    return chat unless Llm::Config.supports_structured_outputs_with_tools?

    chat.with_params(**params, response_format: { type: 'json_object' })
  end

  def with_response_schema(chat, schema)
    return chat unless Llm::Config.supports_structured_outputs_with_tools?

    chat.with_schema(schema)
  end

  def with_provider_temperature(chat, temperature)
    return chat if temperature.nil? || !Llm::Config.supports_temperature?

    chat.with_temperature(temperature)
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end

  def setup_provider
    @provider = Llm::Config.ruby_llm_provider
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end
end
