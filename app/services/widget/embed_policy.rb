# Encapsulates which parent origins may embed a web widget, derived from the
# channel's comma-separated `allowed_domains`. It owns both the `frame-ancestors`
# source string emitted for the browser and the server-side origin check used for
# the cross-origin-isolation CORS echo, so the two stay derived from one list.
class Widget::EmbedPolicy
  def initialize(allowed_domains)
    @domains = allowed_domains.to_s.split(',').map(&:strip).reject(&:empty?)
  end

  # The value for `Content-Security-Policy: frame-ancestors <...>`.
  def frame_ancestors_source
    @domains.join(' ')
  end

  # Whether `origin` (a browser Origin header value) may embed the widget,
  # matched the same way the emitted frame-ancestors sources are: exact host or
  # a "*." subdomain wildcard, honoring a pinned scheme/port and resolving a
  # scheme-less entry against `request_scheme` (so CORS is never broader than the
  # framing policy).
  def allows_origin?(origin, request_scheme:)
    origin_uri = parse_uri(origin)
    return false if origin_uri.nil? || origin_uri.host.blank?

    @domains.any? { |domain| domain_matches?(domain, origin_uri, request_scheme) }
  end

  private

  def domain_matches?(domain, origin_uri, request_scheme)
    domain_uri = parse_uri(domain.include?('//') ? domain : "//#{domain}")
    return false unless domain_uri && host_matches?(domain_uri.host, origin_uri.host)

    scheme_matches?(domain_uri, origin_uri, request_scheme) && port_matches?(domain_uri, origin_uri)
  end

  # Exact host, or a leading "*." CSP wildcard matching any subdomain (not the apex).
  def host_matches?(domain_host, origin_host)
    return false if domain_host.blank? || origin_host.blank?

    domain_host = domain_host.downcase
    origin_host = origin_host.downcase
    return origin_host.end_with?(domain_host.delete_prefix('*')) if domain_host.start_with?('*.')

    domain_host == origin_host
  end

  # A host-only entry has no scheme, so CSP resolves it against the widget
  # response's own scheme (request_scheme) — on an https install the origin must
  # be https too, with an http-response -> https-origin upgrade allowed.
  def scheme_matches?(domain_uri, origin_uri, request_scheme)
    effective_scheme = domain_uri.scheme || request_scheme
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
end
