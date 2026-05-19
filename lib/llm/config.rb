require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze
  DEFAULT_PROVIDER = 'openai'.freeze

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

    def with_api_key(api_key, provider: default_provider, api_base: nil)
      initialize!
      context = RubyLLM.context do |config|
        configure_provider(config, provider: provider, api_key: api_key, api_base: api_base)
      end

      yield context
    end

    def default_provider
      provider_config_value.presence || DEFAULT_PROVIDER
    end

    def default_embedding_provider
      DEFAULT_PROVIDER
    end

    def api_base_for(provider: default_provider, endpoint: api_endpoint)
      return if endpoint.blank?

      normalized_endpoint = endpoint.chomp('/')
      return "#{normalized_endpoint}/v1" if provider.to_s == 'openai' && normalized_endpoint.exclude?('/v1')

      normalized_endpoint
    end

    def embedding_api_base
      api_base_for(provider: default_embedding_provider, endpoint: LlmConstants::OPENAI_API_ENDPOINT)
    end

    def available_providers
      RubyLLM::Provider.providers.keys.map(&:to_s).sort
    end

    def configurable_providers
      providers = available_providers.select do |provider|
        supported_options = [:"#{provider}_api_key", :"#{provider}_api_base"]
        options = provider_configuration_options(provider)
        requirements = RubyLLM::Provider.providers[provider.to_sym].configuration_requirements

        options.intersect?(supported_options) && (requirements - supported_options).empty?
      end
      providers.sort_by { |provider| provider == DEFAULT_PROVIDER ? '' : provider }
    end

    def provider_options
      configurable_providers.index_with do |provider|
        RubyLLM::Provider.providers[provider.to_sym].name
      end
    end

    def default_openai_endpoint?
      default_provider == DEFAULT_PROVIDER && api_endpoint.blank?
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        configure_provider(config, provider: default_provider, api_key: system_api_key, api_base: api_base_for)
        configure_provider(
          config,
          provider: default_embedding_provider,
          api_key: embedding_api_key.presence || system_openai_api_key,
          api_base: embedding_api_base
        )
        config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
        config.logger = Rails.logger
      end
    end

    def configure_provider(config, provider:, api_key:, api_base: nil)
      provider = provider.to_s
      options = provider_configuration_options(provider)
      api_key_option = :"#{provider}_api_key"
      api_base_option = :"#{provider}_api_base"

      config.public_send("#{api_key_option}=", api_key) if api_key.present? && options.include?(api_key_option)
      config.public_send("#{api_base_option}=", api_base) if api_base.present? && options.include?(api_base_option)
    end

    def provider_configuration_options(provider)
      RubyLLM::Provider.providers[provider.to_sym]&.configuration_options || []
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def api_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end

    def embedding_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_API_KEY')&.value
    end

    def system_openai_api_key
      system_api_key if default_openai_endpoint?
    end

    def provider_config_value
      InstallationConfig.find_by(name: 'CAPTAIN_LLM_PROVIDER')&.value
    end
  end
end
