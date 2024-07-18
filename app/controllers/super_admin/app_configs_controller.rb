require 'mini_magick'

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

      handle_favicon(value) if key == 'FAVICON'
      handle_favicon_badge(value) if key == 'FAVICON_BADGE'

      i = InstallationConfig.where(name: key).first_or_create(value: value, locked: false)
      i.value = value
      i.save!
    end
    redirect_to super_admin_settings_path, notice: I18n.t('global_config.update_success')
  end

  private

  def set_config
    @config = params[:config]
  end

  def allowed_configs
    @allowed_configs = %w[FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET FAVICON FAVICON_BADGE]
  end

  def handle_favicon(favicon_url)
    sizes = [16, 32, 96, 512]
    convert_and_save_favicon(favicon_url, sizes)
  end

  def handle_favicon_badge(favicon_url)
    badge_sizes = [16, 32, 96]
    convert_and_save_favicon(favicon_url, badge_sizes, badge: true)
  end

  def convert_and_save_favicon(favicon_url, sizes, badge: false)
    sizes.each do |size|
      save_favicon(favicon_url, size, badge)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to convert and save favicon: #{e.message}"
  end

  def save_favicon(favicon_url, size, badge: false)
    image = MiniMagick::Image.open(favicon_url)
    image.resize "#{size}x#{size}"
    suffix = badge ? '-badge' : ''
    favicon_path = Rails.public_path.join("favicon#{suffix}-#{size}x#{size}.png")
    image.write favicon_path
  end
end

SuperAdmin::AppConfigsController.prepend_mod_with('SuperAdmin::AppConfigsController')
