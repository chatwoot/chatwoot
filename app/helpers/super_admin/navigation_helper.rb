module SuperAdmin::NavigationHelper
  def settings_open?
    params[:controller].in? %w[super_admin/settings super_admin/app_configs]
  end

  def settings_pages
    SuperAdmin::FeaturesHelper.available_features.select do |_feature, attrs|
      attrs['config_key'].present?
    end
  end
end
