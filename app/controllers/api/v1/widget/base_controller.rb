class Api::V1::Widget::BaseController < ActionController::Base
  private

  def conversation
    @conversation ||= ::Conversation.find_by(
      contact_id: auth_token_params[:contact_id],
      inbox_id: auth_token_params[:inbox_id]
    )
  end

  def auth_token_params
    @auth_token_params ||= JWT.decode(
      request.headers[header_name], secret_key, true, algorithm: 'HS256'
    ).first.symbolize_keys
  end

  def header_name
    'X-Auth-Token'
  end

  def secret_key
    Rails.application.secrets.secret_key_base
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_contact
    @contact = @web_widget.inbox.contacts.find(auth_token_params[:contact_id])
  end
end
