class SuperAdmin::AppConfigsController < SuperAdmin::ApplicationController
  before_action :set_config
  before_action :allowed_configs
  def show
    # ref: https://github.com/rubocop/rubocop/issues/7767
    # rubocop:disable Style/HashTransformValues
    @app_config = InstallationConfig.where(name: @allowed_configs)
                                    .pluck(:name, :serialized_value)
                                    .map { |name, serialized_value| [name, serialized_value['value']] }
                                    .to_h
    # rubocop:enable Style/HashTransformValues
  end

  def create
    params['app_config'].each do |key, value|
      next unless @allowed_configs.include?(key)

      i = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
      i.value = value
      i.save!
    end
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_to super_admin_settings_path, notice: 'App Configs updated successfully'
    # rubocop:enable Rails/I18nLocaleTexts
  end

  private

  def set_config
    @config = params[:config]
  end

  def allowed_configs
    @allowed_configs = %w[FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET]
  end
end

SuperAdmin::AppConfigsController.prepend_mod_with('SuperAdmin::AppConfigsController')
