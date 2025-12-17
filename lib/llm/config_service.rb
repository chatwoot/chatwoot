# frozen_string_literal: true

module Llm::ConfigService
  CONFIG_PATH = Rails.root.join('config/llm.yml').freeze

  class << self
    def config
      @config ||= load_config
    end

    def reload!
      @config = load_config
    end

    def providers
      config['providers'] || {}
    end

    def models
      config['models'] || {}
    end

    def features
      config['features'] || {}
    end

    def models_for_feature(feature_key)
      feature = features[feature_key.to_s]
      return [] unless feature

      feature['models'] || []
    end

    def default_model_for_feature(feature_key)
      features.dig(feature_key.to_s, 'default')
    end

    def model_info(model_name)
      models[model_name.to_s]
    end

    def provider_info(provider_name)
      providers[provider_name.to_s]
    end

    def feature_keys
      features.keys
    end

    def valid_model_for_feature?(feature_key, model_name)
      allowed_models = models_for_feature(feature_key)
      allowed_models.include?(model_name.to_s)
    end

    def feature_config(feature_key)
      feature = features[feature_key.to_s]
      return nil unless feature

      {
        models: feature['models'].filter_map do |model_name|
          model = models[model_name]
          next nil unless model

          {
            id: model_name,
            display_name: model['display_name'],
            provider: model['provider'],
            credit_multiplier: model['credit_multiplier']
          }
        end,
        default: feature['default']
      }
    end

    def all_features_config
      features.keys.index_with do |feature_key|
        feature_config(feature_key)
      end
    end

    private

    def load_config
      return {} unless File.exist?(CONFIG_PATH)

      YAML.load_file(CONFIG_PATH) || {}
    end
  end
end
