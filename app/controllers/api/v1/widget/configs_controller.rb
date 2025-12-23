class Api::V1::Widget::ConfigsController < Api::V1::Widget::BaseController
  before_action :set_global_config

  def create
    build_contact
    set_token
  end

  private

  def set_global_config
    config = GlobalConfig.get(
      'LOGO_THUMBNAIL',
      'BRAND_NAME',
      'WIDGET_BRAND_URL',
      'MAXIMUM_FILE_UPLOAD_SIZE',
      'INSTALLATION_NAME'
    )
    
    # Load branding from BrandingConfig if available
    branding = BrandingConfig.instance rescue nil
    if branding
      config['BRAND_NAME'] = branding.brand_name
      config['BRAND_WEBSITE'] = branding.brand_website
      config['WIDGET_BRAND_URL'] = branding.brand_website
      config['LOGO_THUMBNAIL'] = branding.logo_compact_url || branding.logo_main_url || config['LOGO_THUMBNAIL']
    end
    
    @global_config = config
  end

  def set_contact
    @contact_inbox = @web_widget.inbox.contact_inboxes.find_by(
      source_id: auth_token_params[:source_id]
    )
    @contact = @contact_inbox&.contact
  end

  def build_contact
    return if @contact.present?

    @contact_inbox = @web_widget.create_contact_inbox(additional_attributes)
    @contact = @contact_inbox.contact
  end

  def set_token
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
end
