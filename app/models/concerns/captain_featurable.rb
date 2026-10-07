# frozen_string_literal: true

module CaptainFeaturable
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_captain_models
    before_validation :normalize_captain_reasoning_efforts
    validate :validate_captain_models
    validate :validate_captain_reasoning_efforts

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

  private

  def captain_models_with_defaults
    Llm::Models.feature_keys.index_with do |feature_key|
      Llm::FeatureRouter.resolve(feature: feature_key, account: self)[:model]
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
      unless Llm::Models.feature?(feature_key)
        errors.add(:captain_models, "'#{feature_key}' is not a known feature")
        next
      end

      next if Llm::Models.valid_model_for?(feature_key, model_name)

      allowed_models = Llm::Models.models_for(feature_key)
      errors.add(:captain_models, "'#{model_name}' is not a valid model for #{feature_key}. Allowed: #{allowed_models.join(', ')}")
    end
  end

  def normalize_captain_models
    return unless captain_models.is_a?(Hash)

    normalized_models = captain_models.each_with_object({}) do |(feature_key, model_name), result|
      next if model_name.blank?

      result[feature_key.to_s] = model_name.to_s
    end

    self.captain_models = normalized_models.presence
  end

  def normalize_captain_reasoning_efforts
    return unless captain_reasoning_efforts.is_a?(Hash)

    self.captain_reasoning_efforts = captain_reasoning_efforts.compact_blank.presence
  end

  def validate_captain_reasoning_efforts
    return unless captain_reasoning_efforts.is_a?(Hash)

    captain_reasoning_efforts.each do |feature, effort|
      unless Llm::FeatureRouter::REASONING_FEATURES.include?(feature)
        errors.add(:captain_reasoning_efforts, "'#{feature}' does not support an effort override")
        next
      end

      model = Llm::FeatureRouter.resolve(feature: feature, account: self)[:model]
      next if Llm::Models.provider_for(model) == 'openai' && RubyLLM.models.find(model).reasoning_option_values(:effort).include?(effort)

      errors.add(:captain_reasoning_efforts, "'#{effort}' is not supported by #{model} for #{feature}")
    end
  end
end
