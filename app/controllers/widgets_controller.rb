# TODO : Delete this and associated spec once 'api/widget/config' end point is merged
class WidgetsController < ActionController::Base
  include WidgetHelper

  before_action :set_global_config
  before_action :set_web_widget
  before_action :ensure_account_is_active
  before_action :ensure_location_is_supported
  before_action :validate_origin_domain
  before_action :set_token
  before_action :set_contact
  before_action :build_contact
  after_action :allow_iframe_requests

  private

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'WIDGET_BRAND_URL', 'DIRECT_UPLOADS_ENABLED', 'INSTALLATION_NAME')
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error('web widget does not exist')
    render json: { error: 'web widget does not exist' }, status: :not_found
  end

  def validate_origin_domain
    # Only validate origin if website_url is configured
    return if @web_widget.website_url.blank?

    origin_domain = extract_domain_from_origin
    return if domain_allowed?(origin_domain, @web_widget.website_url)

    Rails.logger.warn('Widget access denied.')
    render json: { error: 'Widget access denied.' }, status: :forbidden
  end

  def domain_allowed?(origin_domain, website_url)
    return false if origin_domain.blank?

    # Split website_url by comma to handle multiple domains/wildcards
    allowed_domains = website_url.split(',').map(&:strip).reject(&:blank?)

    allowed_domains.any? do |allowed_domain|
      # Extract domain and protocol from the allowed domain
      allowed_domain_without_protocol = extract_domain_from_url(allowed_domain)
      allowed_protocol = extract_protocol_from_url(allowed_domain)
      origin_protocol = extract_protocol_from_origin

      # Check if the extracted domain starts with wildcard
      if allowed_domain_without_protocol&.start_with?('*.')
        # Handle wildcard domains (e.g., "*.example.com")
        wildcard_suffix = allowed_domain_without_protocol[2..-1] # Remove "*.", keep "example.com"
        origin_domain.end_with?(wildcard_suffix) && origin_protocol == allowed_protocol
      else
        # Handle exact domain and protocol match
        origin_domain == allowed_domain_without_protocol && origin_protocol == allowed_protocol
      end
    end
  end

  def extract_domain_from_origin
    origin = request.headers['Origin']
    return nil if origin.blank?

    extract_domain_from_url(origin)
  end

  def extract_protocol_from_origin
    origin = request.headers['Origin']
    return nil if origin.blank?

    extract_protocol_from_url(origin)
  end

  def extract_domain_from_url(url)
    return nil if url.blank?

    # Parse the URL and extract the domain
    uri = URI.parse(url)
    uri.host&.downcase
  rescue URI::InvalidURIError
    nil
  end

  def extract_protocol_from_url(url)
    return nil if url.blank?

    # Parse the URL and extract the protocol
    uri = URI.parse(url)
    uri.scheme&.downcase
  rescue URI::InvalidURIError
    nil
  end

  def set_token
    @token = permitted_params[:cw_conversation]
    @auth_token_params = if @token.present?
                           ::Widget::TokenService.new(token: @token).decode_token
                         else
                           {}
                         end
  end

  def set_contact
    return if @auth_token_params[:source_id].nil?

    @contact_inbox = ::ContactInbox.find_by(
      inbox_id: @web_widget.inbox.id,
      source_id: @auth_token_params[:source_id]
    )

    @contact = @contact_inbox&.contact
  end

  def build_contact
    return if @contact.present?

    @contact_inbox, @token = build_contact_inbox_with_token(@web_widget, additional_attributes)
    @contact = @contact_inbox.contact
  end

  def ensure_account_is_active
    render json: { error: 'Account is suspended' }, status: :unauthorized unless @web_widget.inbox.account.active?
  end

  def ensure_location_is_supported; end

  def additional_attributes
    if @web_widget.inbox.account.feature_enabled?('ip_lookup')
      { created_at_ip: request.remote_ip }
    else
      {}
    end
  end

  def permitted_params
    params.permit(:website_token, :cw_conversation)
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end
end

WidgetsController.prepend_mod_with('WidgetsController')
