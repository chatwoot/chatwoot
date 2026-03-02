# frozen_string_literal: true

# Makes an HTTP request to an external API.
# Supports Liquid templates in URL, headers, and body.
# Stores the response in a context variable.
class Agent::Nodes::HttpRequestNode < BaseNode
  ALLOWED_METHODS = %w[GET POST PUT PATCH DELETE].freeze
  MAX_RESPONSE_SIZE = 10_000

  protected

  def process
    method = (data['method'] || 'GET').upcase
    raise ArgumentError, "Invalid HTTP method: #{method}" unless ALLOWED_METHODS.include?(method)

    url = render_template(data['url_template'])
    raise ArgumentError, 'URL is required' if url.blank?

    headers = build_headers
    body = build_body(method)
    timeout = [data['timeout_seconds'] || 30, 120].min

    response = make_request(method, url, headers, body, timeout)

    context.set_variable('http_status', response.code)
    context.set_variable('http_body', response.body.to_s.truncate(MAX_RESPONSE_SIZE))

    parsed = parse_response(response)
    context.set_variable('http_response', parsed) if parsed

    { output: { status: response.code, body_size: response.body&.length } }
  end

  private

  def build_headers
    custom = data['headers'] || {}
    custom.transform_values { |v| render_template(v.to_s) }
  end

  def build_body(method)
    return nil if %w[GET DELETE].include?(method)

    body_template = data['body_template']
    return nil if body_template.blank?

    render_template(body_template)
  end

  def make_request(method, url, headers, body, timeout)
    uri = URI.parse(url)
    validate_url!(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = timeout
    http.read_timeout = timeout

    request = build_net_request(method, uri, headers, body)
    http.request(request)
  end

  def build_net_request(method, uri, headers, body)
    klass = Net::HTTP.const_get(method.capitalize)
    request = klass.new(uri)
    headers.each { |k, v| request[k] = v }
    request.body = body if body
    request['Content-Type'] ||= 'application/json' if body
    request
  end

  def validate_url!(uri)
    raise ArgumentError, "Invalid URL scheme: #{uri.scheme}" unless %w[http https].include?(uri.scheme)

    # Basic SSRF protection — don't allow requests to private IPs
    addr = Resolv.getaddress(uri.host)
    ip = IPAddr.new(addr)
    return unless ip.private? || ip.loopback? || ip.link_local?

    raise ArgumentError, 'Requests to private/internal addresses are not allowed'
  end

  def parse_response(response)
    JSON.parse(response.body)
  rescue JSON::ParserError, TypeError
    nil
  end
end
