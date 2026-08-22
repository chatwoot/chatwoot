# frozen_string_literal: true

module CaptainFeaturable
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_captain_models

    # Dynamically define accessor methods for each captain feature
    Llm::FeatureRouter.feature_keys.each do |feature_key|
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
    Llm::FeatureRouter.feature_keys.index_with do |feature_key|
      Llm::FeatureRouter.resolve(feature: feature_key, account: self)[:model]
    end
  end

  def captain_features_with_defaults
    stored_features = captain_features || {}
    Llm::FeatureRouter.feature_keys.index_with do |feature_key|
      stored_features[feature_key] == true
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
end
