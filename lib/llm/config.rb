require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze
  DEFAULT_UTILITY_MODEL = 'gpt-4.1-nano'.freeze
  DEFAULT_PROVIDER = 'openai'.freeze
  AZURE_PROVIDER = 'azure'.freeze
  OPENAI_CHAT_PARAMS_PROVIDERS = %w[azure openai openrouter].freeze

  class << self
    def initialized? = @initialized ||= false

    def initialize!
      return if @initialized

      configure_ruby_llm
      @initialized = true
    end

    def reset! = @initialized = false

    def with_api_key(api_key, provider: default_provider, api_base: nil, auth_token: nil)
      initialize!
      context = RubyLLM.context do |config|
        configure_provider(config, provider: provider, api_key: api_key, api_base: api_base, auth_token: auth_token)
      end

      yield context
    end

    def default_provider = provider_config_value.presence || DEFAULT_PROVIDER

    def captain_utility_model = default_openai_endpoint? ? DEFAULT_UTILITY_MODEL : configured_model.presence || DEFAULT_UTILITY_MODEL

    def api_base_for(provider: default_provider, endpoint: api_endpoint)
      return if endpoint.blank?

      normalized_endpoint = endpoint.chomp('/').delete_suffix('/chat/completions')
      return "#{normalized_endpoint}/v1" if provider.to_s == DEFAULT_PROVIDER && normalized_endpoint.exclude?('/v1')

      normalized_endpoint
    end

    def ruby_llm_provider(provider = default_provider) = provider.to_s

    def captain_model_for(requested_model) = default_openai_endpoint? ? requested_model : configured_model.presence || requested_model

    def available_providers = RubyLLM::Provider.providers.keys.map(&:to_s).sort

    def configurable_providers
      providers = available_providers.select do |provider|
        supported_options = [:"#{provider}_api_key", :"#{provider}_api_base"]
        options = provider_configuration_options(provider)
        requirements = RubyLLM::Provider.providers[provider.to_sym].configuration_requirements

        options.intersect?(supported_options) && (requirements - supported_options).empty?
      end
      providers.sort_by { |provider| provider == DEFAULT_PROVIDER ? '' : provider }
    end

    def provider_options = configurable_providers.index_with { |provider| RubyLLM::Provider.providers[provider.to_sym].name }

    def provider_api_base_options = configurable_providers.index_with { |provider| default_api_base_for_provider(provider) }

    def direct_openai_endpoint?(provider: default_provider, endpoint: api_endpoint)
      provider.to_s == DEFAULT_PROVIDER && default_openai_api_base?(endpoint)
    end

    def default_openai_endpoint? = direct_openai_endpoint?

    def supports_structured_outputs_with_tools? = default_openai_endpoint?

    def supports_temperature? = default_openai_endpoint?

    def supports_openai_chat_params? = OPENAI_CHAT_PARAMS_PROVIDERS.include?(default_provider)

    def api_key_required?(provider = default_provider)
      provider = provider.to_s
      provider_configuration_requirements(provider).include?(:"#{provider}_api_key") || provider == AZURE_PROVIDER
    end

    def api_base_only_provider_configured?(provider: default_provider, endpoint: api_endpoint)
      !api_key_required?(provider) && api_base_for(provider: provider, endpoint: endpoint).present?
    end

    def configure_provider(config, provider:, api_key:, api_base: nil, auth_token: nil)
      options = provider_configuration_options(provider)
      api_key_option = :"#{provider}_api_key"
      api_base_option = :"#{provider}_api_base"

      set_config_value(config, api_key_option, api_key) if api_key.present? && options.include?(api_key_option)
      set_config_value(config, api_base_option, api_base) if api_base.present? && options.include?(api_base_option)
      set_config_value(config, :azure_ai_auth_token, auth_token) if provider.to_s == AZURE_PROVIDER && auth_token.present?
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        configure_provider(config, provider: default_provider, api_key: system_api_key, api_base: api_base_for, auth_token: system_auth_token)
        config.model_registry_file = Rails.root.join('config/llm_models.json').to_s
        config.logger = Rails.logger
      end
    end

    def provider_configuration_options(provider) = RubyLLM::Provider.providers[provider.to_sym]&.configuration_options || []

    def set_config_value(config, option, value)
      setter = :"#{option}="
      config.public_send(setter, value) if config.respond_to?(setter)
    end

    def system_api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value

    def system_auth_token = InstallationConfig.find_by(name: 'CAPTAIN_AZURE_AI_AUTH_TOKEN')&.value

    def api_endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value

    def configured_model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value

    def default_api_base_for_provider(provider)
      return if provider_configuration_requirements(provider).include?(:"#{provider}_api_base")

      config = RubyLLM::Configuration.new
      provider_configuration_requirements(provider).each { |requirement| config.public_send("#{requirement}=", 'dummy') }

      RubyLLM::Provider.providers[provider.to_sym].new(config).api_base
    rescue StandardError
      nil
    end

    def provider_configuration_requirements(provider) = RubyLLM::Provider.providers[provider.to_sym]&.configuration_requirements || []

    def default_openai_api_base?(endpoint)
      normalized_endpoint = endpoint.to_s.chomp('/').delete_suffix('/chat/completions').delete_suffix('/v1')
      normalized_endpoint.blank? || normalized_endpoint == LlmConstants::OPENAI_API_ENDPOINT
    end

    def provider_config_value
      provider = InstallationConfig.find_by(name: 'CAPTAIN_LLM_PROVIDER')&.value
      return provider if configurable_providers.include?(provider)

      nil
    end
  end
end
