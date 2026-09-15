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
    @contact_inbox = find_widget_contact_inbox
    @contact = @contact_inbox&.contact
  end

  def build_contact
    return if @contact.present?

    @contact_inbox = @web_widget.create_contact_inbox(additional_attributes)
    @contact = @contact_inbox.contact
  end

  def set_token
    @token = ::Widget::TokenService.new(payload: ::Widget::TokenService.payload_for(@contact_inbox)).generate_token
  end

  def additional_attributes
    if @web_widget.inbox.account.feature_enabled?('ip_lookup')
      { created_at_ip: request.remote_ip }
    else
      {}
    end
  end
end
