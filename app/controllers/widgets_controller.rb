class WidgetsController < ActionController::Base
  before_action :set_web_widget
  before_action :set_contact
  before_action :build_contact

  private

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  end

  def set_contact
    return if cookies.signed[:cw_source_id].nil?

    @contact = ::ContactInboxes.find_by(
      inbox_id: web_widget.inbox_id,
      source_id: cookies.signed[:cw_source_id]
    )
  end

  def build_contact
    return if @contact.present?

    contact_inbox = @web_widget.create_contact_inbox
    @contact = contact_inbox.contact

    cookies.signed[:cw_source_id] = contact_inbox.source_id
  end

  def permitted_params
    params.permit(:website_token)
  end
end
