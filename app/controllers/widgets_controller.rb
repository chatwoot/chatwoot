class WidgetsController < ActionController::Base
  before_action :set_web_widget
  before_action :set_contact
  before_action :build_contact

  private

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_contact
    return if cookie_params[:source_id].nil?

    contact_inbox = ::ContactInbox.find_by(
      inbox_id: @web_widget.inbox.id,
      source_id: cookie_params[:source_id]
    )

    @contact = contact_inbox.contact
  end

  def build_contact
    return if @contact.present?

    contact_inbox = @web_widget.create_contact_inbox
    @contact = contact_inbox.contact

    cookies.signed[cookie_name] = JSON.generate(
      source_id: contact_inbox.source_id,
      contact_id: @contact.id,
      inbox_id: @web_widget.inbox.id
    ).to_s
  end

  def cookie_params
    cookies.signed[cookie_name] ? JSON.parse(cookies.signed[cookie_name]).symbolize_keys : {}
  end

  def permitted_params
    params.permit(:website_token)
  end

  def cookie_name
    'cw_conversation_' + permitted_params[:website_token]
  end
end
