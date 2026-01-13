# frozen_string_literal: true

module CaptainFeaturable
  extend ActiveSupport::Concern

  included do
    validate :validate_captain_models

    # Dynamically define accessor methods for each captain feature
    Llm::Models.feature_keys.each do |feature_key|
      # Define enabled? methods (e.g., captain_editor_enabled?)
      define_method("captain_#{feature_key}_enabled?") do
        captain_features_with_defaults[feature_key]
      end

      # Define model accessor methods (e.g., captain_editor_model)
      define_method("captain_#{feature_key}_model") do
        captain_models_with_defaults[feature_key]
      end
    end
  end

  def captain_preferences
    {
      models: captain_models_with_defaults,
      features: captain_features_with_defaults
    }.with_indifferent_access
  end

  # TODO: Once we support multiple LLM providers, ensure provider hook is correctly looked up
  # Currently works because the only model/provider is OpenAI
  def openai_hook
    @openai_hook ||= hooks.find_by(app_id: 'openai', status: 'enabled')
  end

  # TODO: Once we support multiple LLM providers, ensure provider key is correctly looked up
  # Currently works because the only model/provider is OpenAI
  def using_openai_hook_key?
    openai_hook&.settings&.dig('api_key').present?
  end

  def captain_api_key
    openai_hook&.settings&.dig('api_key') || captain_system_api_key
  end

  def captain_system_api_key
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end

  private

  def captain_models_with_defaults
    stored_models = captain_models || {}
    Llm::Models.feature_keys.each_with_object({}) do |feature_key, result|
      stored_value = stored_models[feature_key]
      result[feature_key] = if stored_value.present? && Llm::Models.valid_model_for?(feature_key, stored_value)
                              stored_value
                            else
                              Llm::Models.default_model_for(feature_key)
                            end
    end
  end

  def captain_features_with_defaults
    stored_features = captain_features || {}
    Llm::Models.feature_keys.index_with do |feature_key|
      stored_features[feature_key] == true
    end
  end

  def validate_captain_models
    return if captain_models.blank?

    captain_models.each do |feature_key, model_name|
      next if model_name.blank?
      next if Llm::Models.valid_model_for?(feature_key, model_name)

      allowed_models = Llm::Models.models_for(feature_key)
      errors.add(:captain_models, "'#{model_name}' is not a valid model for #{feature_key}. Allowed: #{allowed_models.join(', ')}")
    end
  end
end
