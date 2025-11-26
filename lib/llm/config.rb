require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze
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
      original_key = RubyLLM.config.openai_api_key
      original_base = RubyLLM.config.openai_api_base

      RubyLLM.configure do |c|
        c.openai_api_key = api_key
        c.openai_api_base = api_base
      end

      yield
    ensure
      RubyLLM.configure do |c|
        c.openai_api_key = original_key
        c.openai_api_base = original_base
      end
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = openai_endpoint.chomp('/') if openai_endpoint.present?
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
