require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze
  INIT_MUTEX = Mutex.new

  class << self
    def initialized?
      @initialized ||= false
    end

    def initialize!
      return if @initialized

      INIT_MUTEX.synchronize do
        return if @initialized

        configure_ruby_llm
        refresh_model_registry
        @initialized = true
      end
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

    def refresh_model_registry
      Thread.new do
        RubyLLM.models.refresh!
        RubyLLM.models.save_to_json
      rescue StandardError => e
        Rails.logger.warn "Failed to refresh RubyLLM model registry: #{e.message}"
      end
    end

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = openai_endpoint.chomp('/') if openai_endpoint.present?
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
