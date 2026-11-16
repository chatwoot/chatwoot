class Api::V1::Widget::ConfigsController < Api::V1::Widget::BaseController
  before_action :set_global_config

  def create
    build_contact
    set_token
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

  def set_contact
    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(
      source_id: auth_token_params[:source_id]
    )
    @contact = @contact_inbox&.contact
  end

  def build_contact
    return if @contact.present?

    @contact_inbox = @web_widget.create_contact_inbox(contact_additional_attributes)
    @contact = @contact_inbox.contact
  end

  def set_token
    payload = { source_id: @contact_inbox.source_id, inbox_id: @web_widget.inbox.id }
    @token = ::Widget::TokenService.new(payload: payload).generate_token
  end
end
