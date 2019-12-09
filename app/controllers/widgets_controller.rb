class WidgetsController < ActionController::Base
  before_action :set_web_widget
  before_action :set_token
  before_action :set_contact
  before_action :build_contact

  private

  def set_contact
    return if @auth_token_params[:contact_id].nil?

    @contact = @web_widget.inbox.contacts.find(@auth_token_params[:contact_id])
  end

  def set_token
    @token = permitted_params[:cw_conversation]
    @auth_token_params = if @token.present?
                           ::Widget::TokenService.new(token: @token).decode_token
                         else
                           {}
                         end
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def build_contact
    return if @contact.present?

    contact_inbox = @web_widget.create_contact_inbox
    @contact = contact_inbox.contact

    payload = { contact_id: @contact.id, inbox_id: @web_widget.inbox.id }
    @token = ::Widget::TokenService.new(payload: payload).generate_token
  end

  def permitted_params
    params.permit(:website_token, :cw_conversation)
  end

  def secret_key
    Rails.application.secrets.secret_key_base
  end
end
