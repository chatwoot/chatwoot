module Llm::FeatureRouter
  class UnknownFeatureError < StandardError; end

  class << self
    def resolve(feature:, account: nil)
      feature_key = feature.to_s
      raise UnknownFeatureError, "Unknown LLM feature: #{feature_key}" unless Llm::Models.feature?(feature_key)

      model = account_model_override(account, feature_key)
      source = model.present? ? :account_override : :default
      # When no explicit per-feature override exists, every feature uses the
      # single configured model, so operators manage one model for the whole app.
      model ||= Llm::Config.model

      {
        feature: feature_key,
        provider: Llm::Models.provider_for(model),
        model: model,
        source: source
      }
    end

    private

    def account_model_override(account, feature_key)
      return if Llm::Models.internal_feature?(feature_key)

      model = account&.captain_models&.[](feature_key).presence
      return unless model
      return model if Llm::Models.valid_model_for?(feature_key, model)
      nil
    end
  end
end
