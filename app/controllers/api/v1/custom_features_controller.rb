class Api::V1::CustomFeaturesController < Api::BaseController
  # GET /api/v1/custom_features
  # Returns custom features configuration for frontend consumption
  def index
    service = CustomFeaturesService.instance
    features = service.all_features

    render json: {
      constants: generate_js_constants(features),
      metadata: features,
      feature_names: service.feature_names,
      display_names: service.display_names_map
    }
  end

  private

  def generate_js_constants(features)
    return {} if features.empty?

    features.each_with_object({}) do |feature, constants|
      constant_name = feature['name'].upcase
      constants[constant_name] = feature['name']
    end
  end
end