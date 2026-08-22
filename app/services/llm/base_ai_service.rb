# frozen_string_literal: true

# Base service for LLM operations using RubyLLM.
# New features should inherit from this class.
class Llm::BaseAiService
  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  DEFAULT_TEMPERATURE = 1.0

  attr_reader :model, :temperature

  def initialize(feature: nil, account: nil, fallback_model: nil)
    @llm_feature = feature
    @llm_account = account
    @fallback_model = fallback_model

    Llm::Config.initialize!
    setup_model
    setup_temperature
  end

  def chat(model: @model, temperature: @temperature)
    RubyLLM.chat(model: model).with_temperature(temperature)
  end

  private

  # Strips markdown code fences (```json ... ``` or ``` ... ```) that some
  # LLM providers/gateways wrap around JSON responses despite response_format hints.
  def sanitize_json_response(response)
    return response if response.nil?

    response.strip.sub(/\A```(?:\w*)\s*\n?/, '').sub(/\n?\s*```\s*\z/, '').strip
  end

  def setup_model
    route = feature_route
    @model = route&.dig(:model) || Llm::Config.model
  end

  def feature_route
    return if @llm_feature.blank?

    Llm::FeatureRouter.resolve(feature: @llm_feature, account: @llm_account)
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end
end
