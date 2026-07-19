# TODO : Delete this and associated spec once 'api/widget/config' end point is merged
class WidgetsController < ActionController::Base
  include WidgetHelper

  before_action :set_global_config
  before_action :set_web_widget
  before_action :ensure_account_is_active
  before_action :ensure_location_is_supported
  before_action :set_token
  before_action :set_contact
  before_action :build_contact
  after_action :allow_iframe_requests

  private

  def set_global_config
    @global_config = GlobalConfig.get(
      'LOGO_THUMBNAIL',
      'BRAND_NAME',
      'WIDGET_BRAND_URL',
      'DIRECT_UPLOADS_ENABLED',
      'MAXIMUM_FILE_UPLOAD_SIZE',
      'INSTALLATION_NAME'
    )
  end

  def set_web_widget
    @web_widget = ::Channel::WebWidget.find_by!(website_token: permitted_params[:website_token])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error('web widget does not exist')
    render json: { error: 'web widget does not exist' }, status: :not_found
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
    if @web_widget.allowed_domains.blank? || embedded_from_non_web_origin?
      response.headers.delete('X-Frame-Options')
    else
      response.headers['Content-Security-Policy'] = "frame-ancestors #{allowed_domains.join(' ')}"
    end

    allow_cross_origin_isolation if @web_widget.allow_cross_origin_isolation?
  end

  # When an inbox opts into cross-origin isolation, emit the headers that let the
  # widget load inside a cross-origin-isolated parent page: COEP/CORP, plus a CORS
  # allow-origin echoed back for any origin already trusted via allowed_domains.
  def allow_cross_origin_isolation
    response.headers['Cross-Origin-Embedder-Policy'] = 'credentialless'
    response.headers['Cross-Origin-Resource-Policy'] = 'cross-origin'

    origin = request.headers['Origin']
    return if origin.blank? || !embed_origin_allowed?(origin)

    response.headers['Access-Control-Allow-Origin'] = origin
    response.headers['Vary'] = [response.headers['Vary'], 'Origin'].compact_blank.join(', ')
  end

  # Echo the Origin only when it matches an allowed_domains entry, mirroring how
  # the CSP frame-ancestors source for that entry would match (so CORS is never
  # broader than the framing policy). allowed_domains is host-only by convention
  # ("example.com"), but entries may also pin a scheme/port ("https://example.com").
  def embed_origin_allowed?(origin)
    origin_uri = parse_uri(origin)
    return false if origin_uri.nil? || origin_uri.host.blank?

    allowed_domains.any? { |domain| domain_matches_origin?(domain, origin_uri) }
  end

  def domain_matches_origin?(domain, origin_uri)
    domain_uri = parse_uri(domain.include?('//') ? domain : "//#{domain}")
    return false unless domain_uri && host_matches?(domain_uri.host, origin_uri.host)

    # A scheme is enforced only when the entry pins one (a host-only entry matches
    # any scheme); the port must be the one the entry pins, else the scheme default.
    scheme_matches?(domain_uri, origin_uri) && port_matches?(domain_uri, origin_uri)
  end

  # Match the host the way the emitted frame-ancestors source would: exact match,
  # or a "*." CSP wildcard that matches any subdomain (but not the apex).
  def host_matches?(domain_host, origin_host)
    return false if domain_host.blank? || origin_host.blank?

    domain_host = domain_host.downcase
    origin_host = origin_host.downcase
    return origin_host.end_with?(domain_host.delete_prefix('*')) if domain_host.start_with?('*.')

    domain_host == origin_host
  end

  # A host-only entry has no scheme, so CSP resolves it against the widget
  # response's own scheme (request.scheme) — on an https install that means the
  # origin must be https too, with http-response -> https-origin upgrade allowed.
  def scheme_matches?(domain_uri, origin_uri)
    effective_scheme = domain_uri.scheme || request.scheme
    effective_scheme == origin_uri.scheme || (effective_scheme == 'http' && origin_uri.scheme == 'https')
  end

  def port_matches?(domain_uri, origin_uri)
    (domain_uri.port || origin_uri.default_port) == origin_uri.port
  end

  def parse_uri(value)
    URI.parse(value)
  rescue URI::InvalidURIError
    nil
  end

  def allowed_domains
    @allowed_domains ||= @web_widget.allowed_domains.to_s.split(',').map(&:strip).reject(&:empty?)
  end

  # Mobile WebViews (iOS/Android) load content from file:// or null origins,
  # which cannot match any domain in frame-ancestors. When the per-inbox flag
  # is enabled, skip frame-ancestors for these requests.
  def embedded_from_non_web_origin?
    return false unless @web_widget.allow_mobile_webview?

    origin = request.headers['Origin']
    origin.blank? || origin == 'null' || origin&.start_with?('file://')
  end
end

WidgetsController.prepend_mod_with('WidgetsController')
