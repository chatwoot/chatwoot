require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'llama3.1:8b'.freeze #'gpt-4.1-mini'

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
      context = RubyLLM.context do |config|
        config.openai_api_key = api_key
        config.openai_api_base = api_base
      end

      yield context
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        if (base = captain_api_base)
          config.openai_api_base = base
          config.ollama_api_base = base
        end
        config.logger = Rails.logger
      end
    end

    # OpenAI-compatible base URL (…/v1) shared by Captain chat (Ollama) and embeddings.
    def captain_api_base
      return if openai_endpoint.blank?

      endpoint = openai_endpoint.chomp('/')
      endpoint.end_with?('/v1') ? endpoint : "#{endpoint}/v1"
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end
  end
end
