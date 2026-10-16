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

  # Applies JSON response mode to a RubyLLM chat instance.
  # Uses response_format for OpenAI/DeepSeek; skips for Gemini (relies on prompt instructions).
  def apply_json_mode(llm_chat, extra_params: {})
    return llm_chat if Llm::Config.provider == 'gemini'

    llm_chat.with_params({ response_format: { type: 'json_object' } }.merge(extra_params))
  end

  private

  # Strips markdown code fences (```json ... ``` or ``` ... ```) that some
  # LLM providers/gateways wrap around JSON responses despite response_format hints.
  def sanitize_json_response(response)
    return response if response.nil?

    response.strip.sub(/\A```(?:\w*)\s*\n?/, '').sub(/\n?\s*```\s*\z/, '').strip
  end

  def setup_model
    return @model = provider_model unless Llm::Config.provider == 'openai'

    route = feature_route
    return @model = route[:model] if account_override_route?(route) || captain_v2_assistant?

    @model = @fallback_model.presence || installation_model.presence || route&.dig(:model) || DEFAULT_MODEL
  end

  def feature_route
    return if @llm_feature.blank?

    Llm::FeatureRouter.resolve(feature: @llm_feature, account: @llm_account)
  end

  def account_override_route?(route)
    route&.dig(:source) == :account_override
  end

  def captain_v2_assistant?
    @llm_feature.to_s == 'assistant' && @llm_account&.feature_enabled?('captain_integration_v2')
  end

  def installation_model
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
  end

  def provider_model
    InstallationConfig.find_by(name: MODEL_CONFIG_KEYS[Llm::Config.provider])&.value.presence || Llm::Config.default_model_for_provider
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end
end
