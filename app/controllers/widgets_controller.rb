# TODO : Delete this and associated spec once 'api/widget/config' end point is merged
class WidgetsController < ActionController::Base
  before_action :set_global_config
  before_action :set_web_widget
  before_action :set_token
  before_action :set_contact
  before_action :build_contact
  after_action :allow_iframe_requests

  private

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'WIDGET_BRAND_URL', 'DIRECT_UPLOADS_ENABLED')
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_token
    @token = permitted_params[:cw_conversation]
    @auth_token_params = if @token.present?
                           ::Widget::TokenService.new(token: @token).decode_token
                         else
                           {}
                         end
  end

  def set_contact
    return if @auth_token_params[:source_id].nil?

    @contact_inbox = ::ContactInbox.find_by(
      inbox_id: @web_widget.inbox.id,
      source_id: @auth_token_params[:source_id]
    )

    @contact = @contact_inbox ? @contact_inbox.contact : nil
  end

  def build_contact
    return if @contact.present?

    @contact_inbox = @web_widget.create_contact_inbox(additional_attributes)
    @contact = @contact_inbox.contact

    payload = { source_id: @contact_inbox.source_id, inbox_id: @web_widget.inbox.id }
    @token = ::Widget::TokenService.new(payload: payload).generate_token
  end

  def additional_attributes
    if @web_widget.inbox.account.feature_enabled?('ip_lookup')
      { created_at_ip: request.remote_ip }
    else
      {}
    end
  end

  def permitted_params
    params.permit(:website_token, :cw_conversation)
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end
end
