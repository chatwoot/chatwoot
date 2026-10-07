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
      end

      yield context
    end

    # CAPTAIN_OPEN_AI_ENDPOINT as an OpenAI-compatible base URL. `/v1` is appended only when the path has no
    # version segment yet, the rule ruby-openai applies to its uri_base, so `https://api.openai.com/`,
    # `https://openrouter.ai/api/v1` and `https://example.openai.azure.com/openai/v1` each resolve to one /v1.
    def openai_api_base
      endpoint = openai_endpoint.to_s.strip.chomp('/').presence || LlmConstants::OPENAI_API_ENDPOINT
      versioned_path?(endpoint) ? endpoint : "#{endpoint}/v1"
    end

    private

    def versioned_path?(endpoint)
      URI.parse(endpoint).path.to_s.match?(%r{/v\d+})
    rescue URI::InvalidURIError
      false
    end

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = openai_api_base if openai_endpoint.present?
        config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
        config.logger = Rails.logger
      end
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end
  end
end
