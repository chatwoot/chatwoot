module WhiskerAi
  class ProviderResolver
    pattr_initialize [:account!, :feature!]

    def resolve
      provider = find_provider
      return nil unless provider

      {
        api_key: provider.api_key,
        api_base: provider.api_base,
        model: select_model(provider),
        provider_name: provider.name
      }
    end

    def resolve_with_fallback
      # Try primary first, then fallbacks in order
      providers = account.whisker_ai_providers.enabled.ordered

      providers.each do |provider|
        result = resolve_from_provider(provider)
        return result if result
      end

      # Fall back to system LLM config
      system_fallback
    end

    private

    def find_provider
      # Prefer primary provider
      primary = account.whisker_ai_providers.enabled.primary.first
      return primary if primary

      # Fall back to first enabled provider
      account.whisker_ai_providers.enabled.ordered.first
    end

    def resolve_from_provider(provider)
      model = select_model(provider)
      return nil unless model

      {
        api_key: provider.api_key,
        api_base: provider.api_base,
        model: model,
        provider_name: provider.name
      }
    end

    def select_model(provider)
      models = provider.models
      return nil if models.blank?

      # Feature-specific model routing
      case feature
      when :summary, :reply_suggestion
        models.first # Use primary model for most features
      when :rewrite
        models.first
      when :label_suggestion
        models.last # Can use cheaper model
      else
        models.first
      end
    end

    def system_fallback
      api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
      endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value

      return nil unless api_key.present?

      {
        api_key: api_key,
        api_base: "#{(endpoint || 'https://api.openai.com').chomp('/')}/v1",
        model: Llm::Config::DEFAULT_MODEL,
        provider_name: 'system'
      }
    end
  end
end
