module Llm::Models
  CONFIG = YAML.load_file(Rails.root.join('config/llm.yml')).freeze

  class << self
    def providers = CONFIG.fetch('providers')
    def models = CONFIG.fetch('models')
    def features = CONFIG.fetch('features')
    def feature_keys = features.keys

    def feature?(feature)
      features.key?(feature.to_s)
    end

    def default_model_for(feature)
      features.dig(feature.to_s, 'default')
    end

    def models_for(feature)
      features.dig(feature.to_s, 'models') || []
    end

    def valid_model_for?(feature, model_name)
      models_for(feature).include?(model_name.to_s)
    end

    def model_config(model_name)
      models[model_name.to_s]
    end

    def provider_for(model_name)
      model_config(model_name)&.dig('provider')
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
        default: feature['default']
      }
    end
  end
end
