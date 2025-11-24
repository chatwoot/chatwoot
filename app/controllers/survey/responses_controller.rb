class Survey::ResponsesController < ActionController::Base
  before_action :set_global_config
  def show; end

  private

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'WIDGET_BRAND_URL', 'INSTALLATION_NAME').merge(
      MAX_ATTACHMENT_SIZE_MB: ENV.fetch('MAX_ATTACHMENT_SIZE_MB', 40).to_i
    )
  end
end
