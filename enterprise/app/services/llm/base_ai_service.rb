# frozen_string_literal: true

# Base service for LLM operations using RubyLLM.
# New features should inherit from this class.
#
# Subclasses should implement:
# - feature_name: Returns the feature key (e.g., 'assistant', 'copilot') for model lookup
# - account: Returns the Account instance for per-account model configuration
#
# If these methods are not implemented, falls back to InstallationConfig or DEFAULT_MODEL.
class Llm::BaseAiService
  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  DEFAULT_TEMPERATURE = 1.0

  attr_reader :temperature

  def initialize
    Llm::Config.initialize!
    setup_temperature
  end

  def model
    @model ||= determine_model
  end

  def chat(model: self.model, temperature: @temperature)
    RubyLLM.chat(model: model).with_temperature(temperature)
  end

  private

  def determine_model
    if respond_to?(:feature_name, true) && respond_to?(:account, true) && account.present?
      account_model = account.captain_preferences.dig(:models, feature_name.to_s)
      return account_model if account_model.present?
    end

    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    config_value.presence || DEFAULT_MODEL
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end
end
