class WidgetsController < ActionController::Base
  before_action :set_web_widget, only: [:show]
  before_action :set_token, only: [:show]
  before_action :set_contact, only: [:show]
  before_action :build_contact, only: [:show]
  before_action :find_contact, only: [:update_contact]
  before_action :find_message, only: [:update_contact]

  def show; end

  def update_contact
    @contact.update!(permitted_params[:contact])
    @message&.update!(input_submitted: true)
    render json: @contact
  rescue StandardError => e
    render json: { error: @contact.errors, message: e.message }.to_json, status: 500
  end

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
    params.permit(:website_token, :cw_conversation, :message_id, :source_id, contact: [:name, :email, :phone_number])
  end

  def secret_key
    Rails.application.secrets.secret_key_base
  end

  def find_contact
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    contact_inbox = ::ContactInbox.find_by!(
      inbox_id: @web_widget.inbox.id,
      source_id: params[:source_id]
    )
    @contact = contact_inbox ? contact_inbox.contact : nil
  end

  def find_message
    return unless permitted_params[:message_id]

    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
    @message = @web_widget.inbox.messages.find(permitted_params[:message_id])
  end
end
