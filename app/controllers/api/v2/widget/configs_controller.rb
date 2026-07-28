class Api::V2::Widget::ConfigsController < Api::V2::Widget::BaseController
  before_action :set_global_config

  def show
    @ai_agent = ai_agent_config
    @announcements = inbox.widget_announcements.active.order(created_at: :desc)
  end

  private

  def set_global_config
    @global_config = GlobalConfig.get(
      'LOGO_THUMBNAIL',
      'BRAND_NAME',
      'WIDGET_BRAND_URL',
      'MAXIMUM_FILE_UPLOAD_SIZE',
      'INSTALLATION_NAME'
    )
  end

  # Overridden in enterprise to expose the connected Captain assistant
  def ai_agent_config
    nil
  end
end

Api::V2::Widget::ConfigsController.prepend_mod_with('Api::V2::Widget::ConfigsController')
