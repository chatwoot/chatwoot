class Api::V1::Widget::BaseController < ApplicationController
  private

  def conversation
    @conversation ||= ::Conversation.find_by(
      contact_id: auth_token_params[:contact_id],
      inbox_id: auth_token_params[:inbox_id]
    )
  end

  def auth_token_params
    @auth_token_params ||= ::Widget::TokenService.new(token: request.headers[header_name]).decode_token
  end

  def header_name
    'X-Auth-Token'
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_contact
    @contact = @web_widget.inbox.contacts.find(auth_token_params[:contact_id])
  end
end
