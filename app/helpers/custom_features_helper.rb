module CustomFeaturesHelper
  # Embed custom features configuration in HTML for immediate frontend access
  def embed_custom_features_config
    service = CustomFeaturesService.instance
    
    javascript_tag do
      raw <<~JS
        // Custom Features Configuration - Auto-loaded from config/custom_features.yml
        window.CUSTOM_FEATURES_CONFIG = {
          constants: #{service.js_constants_string.html_safe},
          metadata: #{service.metadata_json.html_safe},
          feature_names: #{service.feature_names.to_json.html_safe},
          display_names: #{service.display_names_map.to_json.html_safe}
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

  # Generate feature metadata as JSON for frontend consumption
  def custom_features_metadata_json
    service = CustomFeaturesService.instance
    service.all_features.to_json
  end

  # Check if custom features are available
  def custom_features_available?
    CustomFeaturesService.instance.all_features.any?
  end

  # Get custom feature by name with fallback
  def custom_feature_info(name)
    CustomFeaturesService.instance.find_feature(name) || {}
  end
end