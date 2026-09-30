module Llm::FeatureRouter
  class UnknownFeatureError < StandardError; end

  CAPTAIN_V2_ASSISTANT_MODEL = 'gpt-5.2'.freeze
  GPT_6_REASONING_ONLY_MODELS = %w[gpt-6-astra gpt-6.1-sol].freeze

  class << self
    def resolve(feature:, account: nil)
      feature_key = feature.to_s
      raise UnknownFeatureError, "Unknown LLM feature: #{feature_key}" unless Llm::Models.feature?(feature_key)

      model, source = model_and_source(account, feature_key)

      {
        feature: feature_key,
        provider: provider_for(model, source),
        model: model,
        source: source,
        reasoning_effort: reasoning_effort(feature: feature_key, model: model)
      }
    end

    def reasoning_effort(feature:, model:)
      return unless Llm::Models.provider_for(model) == 'openai' && standard_openai_endpoint?

      effort = Llm::Models.features.dig(feature.to_s, 'reasoning_effort') || 'none'
      effort = 'low' if effort == 'none' && GPT_6_REASONING_ONLY_MODELS.include?(model)
      effort.to_sym if RubyLLM.models.find(model).reasoning_option_values(:effort).include?(effort)
    end

    def standard_openai_endpoint?
      endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
      endpoint.blank? || endpoint.chomp('/') == LlmConstants::OPENAI_API_ENDPOINT
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
      return unless feature_key == 'conversation_completion'
      return unless ChatwootApp.self_hosted_paid?

      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence
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
