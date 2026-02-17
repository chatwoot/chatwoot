require 'ruby_llm'

module Llm::Config
  DEFAULT_MODELS = {
    'openai' => 'gpt-4o-mini',
    'gemini' => 'gemini-2.0-flash',
    'deepseek' => 'deepseek-chat'
  }.freeze

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

    def provider
      InstallationConfig.find_by(name: 'CAPTAIN_AI_PROVIDER')&.value.presence || 'openai'
    end

    def default_model_for_provider
      DEFAULT_MODELS[provider] || DEFAULT_MODEL
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
        configure_openai(config)
        configure_gemini(config)
        configure_deepseek(config)
        config.logger = Rails.logger
      end
    end

    def configure_openai(config)
      return unless openai_api_key.present?

      config.openai_api_key = openai_api_key
      config.openai_api_base = openai_endpoint.chomp('/') if openai_endpoint.present?
    end

    def configure_gemini(config)
      return unless gemini_api_key.present?

      config.gemini_api_key = gemini_api_key
    end

    def configure_deepseek(config)
      return unless deepseek_api_key.present?

      config.openai_api_key = deepseek_api_key if provider == 'deepseek'
      config.openai_api_base = 'https://api.deepseek.com' if provider == 'deepseek'
    end

    def openai_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end

    def gemini_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_GEMINI_API_KEY')&.value
    end

    def deepseek_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_DEEPSEEK_API_KEY')&.value
    end
  end
end
