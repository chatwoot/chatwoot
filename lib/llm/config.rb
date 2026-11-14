require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-6-luna'.freeze
  API_KEY_CONFIGS = {
    'openai' => 'CAPTAIN_OPEN_AI_API_KEY',
    'anthropic' => 'CAPTAIN_ANTHROPIC_API_KEY'
  }.freeze

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

    def with_api_key(api_key, api_base: nil, provider: 'openai')
      initialize!
      context = RubyLLM.context do |config|
        if provider.to_s == 'anthropic'
          config.anthropic_api_key = api_key
        else
          config.openai_api_key = api_key
          config.openai_api_base = api_base
        end
      end

      yield context
    end

    def api_key_for(provider)
      config_name = API_KEY_CONFIGS[provider.to_s]
      return if config_name.blank?

      InstallationConfig.find_by(name: config_name)&.value.presence
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = "#{openai_endpoint.chomp('/')}/v1" if openai_endpoint.present?
        config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
        config.openai_protocol = :chat_completions
        config.logger = Rails.logger
      end
    end

    def system_api_key
      api_key_for('openai')
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end
  end
end
