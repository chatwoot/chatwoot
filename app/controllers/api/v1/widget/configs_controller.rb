class Api::V1::Widget::ConfigsController < Api::V1::Widget::BaseController
  include WidgetHelper

  before_action :set_global_config

  def create
    @token, @pubsub_token = visitor_session(@web_widget, request.headers['X-Auth-Token'], auth_token_params, @contact_inbox)
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

  # Unlike the other widget endpoints, this one also serves visitors without a token.
  def set_contact
    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(source_id: auth_token_params[:source_id])
    @contact = @contact_inbox&.contact
  end
end
