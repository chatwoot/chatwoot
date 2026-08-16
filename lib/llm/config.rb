require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze

  class << self
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

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = api_base if openai_endpoint.present?
        config.openrouter_api_key = system_api_key if openrouter_endpoint?
        config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
        config.logger = Rails.logger
      end
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence
    end

    def openrouter_endpoint?
      openai_endpoint&.include?('openrouter.ai')
    end
  end
end
