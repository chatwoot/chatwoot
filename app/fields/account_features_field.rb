class AccountFeaturesField < Administrate::Field::Base
  def features
    data.is_a?(Hash) ? data : {}
  end

  def feature_enabled?(name)
    features[name.to_s] == true || features[name.to_sym] == true
  end

  def display_name_for(feature_name)
    SuperAdmin::AccountFeaturesHelper.feature_display_names[feature_name] || feature_name.to_s.titleize
  end

  def partitioned_features
    SuperAdmin::AccountFeaturesHelper.partition_features(features)
  end
end
