class Survey::ResponsesController < ActionController::Base
  before_action :set_global_config
  def show; end

  private

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'WIDGET_BRAND_URL')
  end
end
