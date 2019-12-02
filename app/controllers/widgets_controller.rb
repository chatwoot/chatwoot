class WidgetsController < ActionController::Base
  before_action :set_web_widget
  before_action :set_token
  before_action :set_contact
  before_action :build_contact

  def show; end

  def update_contact; end

  private

  def set_contact
    return if cookie_params[:source_id].nil?

    contact_inbox = ::ContactInbox.find_by(
      inbox_id: @web_widget.inbox.id,
      source_id: cookie_params[:source_id]
    )

    @contact = contact_inbox ? contact_inbox.contact : nil
  end

  def set_token
    @token = conversation_token
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def build_contact
    return if @contact.present?

    contact_inbox = @web_widget.create_contact_inbox
    @contact = contact_inbox.contact

    payload = {
      source_id: contact_inbox.source_id,
      contact_id: @contact.id,
      inbox_id: @web_widget.inbox.id
    }
    @token = JWT.encode payload, secret_key, 'HS256'
  end

  def cookie_params
    return @cookie_params if @cookie_params.present?

    if conversation_token.present?
      begin
        @cookie_params = JWT.decode(
          conversation_token, secret_key, true, algorithm: 'HS256'
        ).first.symbolize_keys
      rescue StandardError
        @cookie_params = {}
      end
      return @cookie_params
    end
    {}
  end

  def conversation_token
    permitted_params[:cw_conversation]
  end

  def permitted_params
    params.permit(:website_token, :cw_conversation)
  end

  def secret_key
    Rails.application.secrets.secret_key_base
  end
end
