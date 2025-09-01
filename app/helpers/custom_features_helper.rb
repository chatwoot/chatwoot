module CustomFeaturesHelper
  # Embed custom features configuration in HTML for immediate frontend access
  def embed_custom_features_config
    javascript_tag do
      raw <<~JS
        // Custom Features Configuration - Auto-loaded from config/custom_features.yml
        window.CUSTOM_FEATURES_CONFIG = {
          constants: #{CustomFeaturesService.js_constants_string.html_safe},
          metadata: #{CustomFeaturesService.metadata_json.html_safe},
          feature_names: #{CustomFeaturesService.feature_names.to_json.html_safe},
          display_names: #{CustomFeaturesService.display_names_map.to_json.html_safe}
        };

        // Helper functions for custom features
        window.isCustomFeatureEnabled = function(featureName, account) {
          return account?.custom_features?.includes(featureName) || false;
        };

        window.getCustomFeatureInfo = function(featureName) {
          return window.CUSTOM_FEATURES_CONFIG.metadata.find(f => f.name === featureName) || null;
        };

        window.getCustomFeatureDisplayName = function(featureName) {
          const info = window.getCustomFeatureInfo(featureName);
          return info?.display_name || featureName;
        };
      JS
    end
  end

  # Get custom features configuration JavaScript content (without script tags)
  def custom_features_config_js
    <<~JS
      // Custom Features Configuration - Auto-loaded from config/custom_features.yml
      window.CUSTOM_FEATURES_CONFIG = {
        constants: #{CustomFeaturesService.js_constants_string.html_safe},
        metadata: #{CustomFeaturesService.metadata_json.html_safe},
        feature_names: #{CustomFeaturesService.feature_names.to_json.html_safe},
        display_names: #{CustomFeaturesService.display_names_map.to_json.html_safe}
      };

      // Helper functions for custom features
      window.isCustomFeatureEnabled = function(featureName, account) {
        return account?.custom_features?.includes(featureName) || false;
      };

      window.getCustomFeatureInfo = function(featureName) {
        return window.CUSTOM_FEATURES_CONFIG.metadata.find(f => f.name === featureName) || null;
      };

      window.getCustomFeatureDisplayName = function(featureName) {
        const info = window.getCustomFeatureInfo(featureName);
        return info?.display_name || featureName;
      };
    JS
  end

  # Generate feature metadata as JSON for frontend consumption
  def custom_features_metadata_json
    CustomFeaturesService.all_features.to_json
  end

  # Check if custom features are available
  def custom_features_available?
    CustomFeaturesService.all_features.any?
  end

  # Get custom feature by name with fallback
  def custom_feature_info(name)
    CustomFeaturesService.find_feature(name) || {}
  end
end