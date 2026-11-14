# Lists the chat models a provider's API offers for the installation's key, so self-hosted
# installations can use new models without waiting for config/llm.yml to name them.
module Llm::ProviderModels
  # OpenAI stays on the curated list in config/llm.yml: its models endpoint mixes chat, audio,
  # image, moderation and retired models without saying which is which.
  LISTED_PROVIDERS = %w[anthropic].freeze
  CACHE_TTL = 12.hours
  FAILURE_CACHE_TTL = 5.minutes

  class << self
    # Returns [{ 'id', 'display_name', 'provider' }] for every listed provider with an API key, newest first.
    def all
      return [] if ChatwootApp.chatwoot_cloud?

      LISTED_PROVIDERS.flat_map { |provider| models_for(provider) }
    end

    def find(model_name)
      all.find { |model| model['id'] == model_name.to_s }
    end

    private

    def models_for(provider)
      api_key = Llm::Config.api_key_for(provider)
      return [] if api_key.blank?

      key = cache_key(provider, api_key)
      cached = Rails.cache.read(key)
      return cached unless cached.nil?

      models = fetch(provider, api_key)
      Rails.cache.write(key, models || [], expires_in: models ? CACHE_TTL : FAILURE_CACHE_TTL)
      models || []
    end

    def fetch(provider, api_key)
      listed = Llm::Config.with_api_key(api_key, provider: provider) do |context|
        RubyLLM::Provider.resolve!(provider).new(context.config).list_models
      end

      listed.select { |model| model.type == :chat }
            .sort_by { |model| model.created_at.to_i }
            .reverse
            .map { |model| { 'id' => model.id, 'display_name' => model.name, 'provider' => provider } }
    rescue StandardError => e
      Rails.logger.warn("[Llm::ProviderModels] Could not list #{provider} models: #{e.class}: #{e.message}")
      nil
    end

    # The key digest keeps a rotated key from serving the previous key's list.
    def cache_key(provider, api_key)
      "llm:provider_models:#{provider}:#{Digest::SHA256.hexdigest(api_key)[0, 16]}"
    end
  end
end
