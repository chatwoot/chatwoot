module Llm::Models
  CONFIG = YAML.load_file(Rails.root.join('config/llm.yml')).freeze

  class << self
    def providers = CONFIG.fetch('providers')
    def models = CONFIG.fetch('models')
    def features = CONFIG.fetch('features')
    def feature_keys = features.reject { |_key, config| config['internal'] }.keys
    def internal_feature_keys = features.select { |_key, config| config['internal'] }.keys
    def model_feature_keys = features.keys

    def internal_feature?(feature)
      features.dig(feature.to_s, 'internal') == true
    end

    def feature?(feature)
      features.key?(feature.to_s)
    end

    # Self-hosted installations with no key for the default model's provider use the default of a provider they configured.
    def default_model_for(feature)
      default_model = features.dig(feature.to_s, 'default')
      return default_model unless provider_models?(feature)
      return default_model if Llm::Config.api_key_for(provider_for(default_model)).present?

      configured_provider_default || default_model
    end

    def models_for(feature)
      curated_models = features.dig(feature.to_s, 'models') || []
      return curated_models unless provider_models?(feature)

      provider_models = Llm::ProviderModels.all
      listed_providers = provider_models.pluck('provider').uniq
      curated_models.reject { |model_name| listed_providers.include?(provider_for(model_name)) } + provider_models.pluck('id')
    end

    def provider_models?(feature)
      features.dig(feature.to_s, 'provider_models') == true && !ChatwootApp.chatwoot_cloud?
    end

    def valid_model_for?(feature, model_name)
      models_for(feature).include?(model_name.to_s)
    end

    def model_config(model_name)
      models[model_name.to_s] || Llm::ProviderModels.find(model_name)
    end

    def provider_for(model_name)
      model_config(model_name)&.dig('provider')
    end

    # config/llm.yml can override the registry, which `rake ruby_llm:refresh_models` regenerates.
    def temperature_for(model_name, temperature)
      supported = model_config(model_name)&.dig('temperature')
      supported = registry_temperature_support(model_name) if supported.nil?
      temperature unless supported == false
    end

    def feature_config(feature_key)
      feature = features[feature_key.to_s]
      return nil unless feature

      {
        models: models_for(feature_key).map do |model_name|
          model = model_config(model_name)
          {
            id: model_name,
            display_name: model['display_name'],
            provider: model['provider'],
            coming_soon: model['coming_soon'],
            credit_multiplier: model['credit_multiplier']
          }
        end,
        default: default_model_for(feature_key)
      }
    end

    private

    def configured_provider_default
      _provider, config = providers.find do |provider, provider_config|
        provider_config['default_model'].present? && Llm::Config.api_key_for(provider).present?
      end
      config&.dig('default_model')
    end

    # Models listed live by a provider are not in the bundled registry.
    def registry_temperature_support(model_name)
      RubyLLM.models.find(model_name).metadata[:temperature]
    rescue RubyLLM::ModelNotFoundError
      nil
    end
  end
end
