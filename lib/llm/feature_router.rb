module Llm::FeatureRouter
  class UnknownFeatureError < StandardError; end

  CAPTAIN_V2_ASSISTANT_MODEL = 'gpt-5.2'.freeze
  CUSTOM_ENDPOINT_FEATURES = %w[editor label_suggestion].freeze

  class << self
    def resolve(feature:, account: nil)
      feature_key = feature.to_s
      raise UnknownFeatureError, "Unknown LLM feature: #{feature_key}" unless Llm::Models.feature?(feature_key)

      model, source = model_and_source(account, feature_key)

      {
        feature: feature_key,
        provider: provider_for(model, source),
        model: model,
        source: source
      }
    end

    private

    def model_and_source(account, feature_key)
      account_model = account_model_override(account, feature_key)
      return [account_model, :account_override] if account_model.present?

      installation_model = installation_model_override(feature_key)
      return [installation_model, :installation_override] if installation_model.present?

      [captain_assistant_model(account, feature_key) || Llm::Models.default_model_for(feature_key), :default]
    end

    def account_model_override(account, feature_key)
      model = account&.captain_models&.[](feature_key).presence
      return unless model
      return model if Llm::Models.valid_model_for?(feature_key, model)
    end

    def installation_model_override(feature_key)
      return unless installation_model_applies?(feature_key)

      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence
    end

    # The reply editor's AI actions run on `editor` and `label_suggestion`. A self-hosted installation that
    # points CAPTAIN_OPEN_AI_ENDPOINT at another OpenAI-compatible provider cannot serve the OpenAI default
    # model names there, so those features follow CAPTAIN_OPEN_AI_MODEL, as Captain itself does.
    def installation_model_applies?(feature_key)
      return ChatwootApp.self_hosted_paid? if feature_key == 'conversation_completion'
      return false unless CUSTOM_ENDPOINT_FEATURES.include?(feature_key)
      return false if ChatwootApp.chatwoot_cloud?

      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.present?
    end

    def provider_for(model, source)
      Llm::Models.provider_for(model) || ('openai' if source == :installation_override)
    end

    def captain_assistant_model(account, feature_key)
      return unless feature_key == 'assistant'
      return unless account&.feature_enabled?('captain_integration')

      CAPTAIN_V2_ASSISTANT_MODEL
    end
  end
end
