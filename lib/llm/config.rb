require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'openrouter/free'.freeze

  class << self
    # Single source of truth for the model used across every Captain feature.
    # Prefers the configured model (CAPTAIN_OPEN_AI_MODEL via .env or the Super
    # Admin installation config), so operators never need to set per-feature
    # gpt/claude/gemini names. Only falls back to the default when nothing is
    # configured.
    def model
      installation_model.presence || DEFAULT_MODEL
    end
    def initialized?
      @initialized ||= false
    end

    def initialize!
      return if @initialized

      configure_ruby_llm
      @initialized = true
    end

    def reset!
      @initialized = false
    end

    def with_api_key(api_key, api_base: nil)
      initialize!
      context = RubyLLM.context do |config|
        config.openai_api_key = api_key
        config.openai_api_base = api_base
        config.openrouter_api_key = api_key if openrouter_endpoint?
      end

      yield context
    end

    # Normalized OpenAI-compatible base URL. Appends /v1 only when it is not
    # already present, so the configured endpoint works whether it is a provider
    # root (https://api.openai.com or https://openrouter.ai/api) or already
    # already carries the version path (/v1). Single source of truth for consumers that
    # previously hand-rolled "<endpoint>/v1".
    def api_base
      endpoint = openai_endpoint.presence || LlmConstants::OPENAI_API_ENDPOINT
      endpoint = endpoint.chomp('/')
      endpoint.end_with?('/v1') ? endpoint : "#{endpoint}/v1"
    end

    # Reads a Captain integration setting from the process environment first,
    # falling back to the installation_config row (Super Admin console). This
    # lets operators configure the LLM/Firecrawl credentials via .env without
    # needing console access.
    def system_api_key
      config_value('CAPTAIN_OPEN_AI_API_KEY')
    end

    def openai_endpoint
      config_value('CAPTAIN_OPEN_AI_ENDPOINT').presence
    end

    def installation_model
      config_value('CAPTAIN_OPEN_AI_MODEL').presence
    end

    def embedding_model
      config_value('CAPTAIN_EMBEDDING_MODEL').presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
    end

    def firecrawl_api_key
      config_value('CAPTAIN_FIRECRAWL_API_KEY')
    end

    def openrouter_endpoint?
      openai_endpoint&.include?('openrouter.ai')
    end

    def provider_for(model_name)
      model = model_name.to_s.downcase
      LlmConstants::PROVIDER_PREFIXES.each do |provider, prefixes|
        return provider if prefixes.any? { |prefix| model.start_with?(prefix) }
      end
      nil
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = api_base if openai_endpoint.present?
        config.openrouter_api_key = system_api_key if openrouter_endpoint?
        config.logger = Rails.logger
      end
    end

    def config_value(config_name)
      ENV.fetch(config_name, nil).presence || InstallationConfig.find_by(name: config_name)&.value
    end
  end
end
