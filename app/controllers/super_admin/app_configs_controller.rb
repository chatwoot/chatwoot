class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
  def show
    @allowed_configs = %w[FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET]
    # ref: https://github.com/rubocop/rubocop/issues/7767
    # rubocop:disable Style/HashTransformValues
    @fb_config = InstallationConfig.where(name: @allowed_configs)
                                   .pluck(:name, :serialized_value)
                                   .map { |name, serialized_value| [name, serialized_value['value']] }
                                   .to_h
    # rubocop:enable Style/HashTransformValues
  end

  def create
    params['app_config'].each do |key, value|
      i = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
      i.value = value
      i.save!
    end
    redirect_to super_admin_app_config_url
  end
end
