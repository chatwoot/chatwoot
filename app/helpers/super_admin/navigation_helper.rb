module SuperAdmin::NavigationHelper
  def settings_open?
    return false if params[:controller] == 'super_admin/email_layouts' && params[:account_id].present?

    params[:controller].in? %w[super_admin/settings super_admin/app_configs super_admin/email_layouts]
  end

  def settings_pages
    features = SuperAdmin::FeaturesHelper.available_features.select do |_feature, attrs|
      attrs['config_key'].present? && attrs['enabled']
    end

    # Add general at the beginning
    general_feature = [['general', { 'config_key' => 'general', 'name' => 'General' }]]

    general_feature + features.to_a
  end
end
