# frozen_string_literal: true

module CaptainFeaturable
  extend ActiveSupport::Concern

  included do
    # Dynamically define accessor methods for each captain feature
    Llm::ConfigService.feature_keys.each do |feature_key|
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
end
