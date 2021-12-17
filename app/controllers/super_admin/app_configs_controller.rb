class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
  def show
    @fb_config = InstallationConfig.where(name: %w[FB_APP_ID FB_VERIFY_TOKEN FB_TOKEN])
  end

  def create
    params['app_config'].each do |key, value|
      i = InstallationConfig.find_by(name: key)
      i.value = value
      i.save!
    end
    redirect_to super_admin_app_config_url
  end
end
