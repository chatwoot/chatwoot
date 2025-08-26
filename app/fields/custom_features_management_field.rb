require 'administrate/field/base'

class CustomFeaturesManagementField < Administrate::Field::Base
  def data
    return [] unless resource.respond_to?(:custom_features)
    resource.custom_features
  end

  def to_s
    data.is_a?(Array) ? data.join(', ') : '[]'
  end

  def all_custom_features
    return [] unless defined?(CustomFeaturesManagerService)
    CustomFeaturesManagerService.instance.all_custom_features
  end

  def feature_display_names
    return {} unless defined?(CustomFeaturesManagerService)
    CustomFeaturesManagerService.instance.feature_display_names
  end

  def features_with_metadata
    return [] unless defined?(CustomFeaturesManagerService)
    CustomFeaturesManagerService.instance.features_with_metadata
  end

  def selected_features
    # If we have direct array data, use it (for rendering after form submission)
    return data if data.is_a?(Array)

    # Otherwise, use the service to retrieve the data
    if resource.respond_to?(:custom_features)
      return resource.custom_features
    end

    # Fallback to empty array if no data available
    []
  end
end