class SafeFetch::PrivateNetworkRequest
  def initialize(options)
    @options = options
  end

  def perform(&)
    url = options.url
    original_url = url
    original_uri = URI(url)

    (SsrfFilter::DEFAULT_MAX_REDIRECTS + 1).times do
      uri = URI(url)
      validate_scheme!(uri)

      response, next_url = fetch_once(uri, resolved_addresses(uri.hostname).sample.to_s, original_uri, &)
      return response if next_url.nil?

      url = next_url
    end

    raise SsrfFilter::TooManyRedirects, "Got #{SsrfFilter::DEFAULT_MAX_REDIRECTS} redirects fetching #{original_url}"
  end

  private

  attr_reader :options

  def validate_scheme!(uri)
    return if SsrfFilter::DEFAULT_SCHEME_WHITELIST.include?(uri.scheme)

    raise SsrfFilter::InvalidUriScheme, "URI scheme '#{uri.scheme}' not in whitelist: #{SsrfFilter::DEFAULT_SCHEME_WHITELIST}"
  end

  def resolved_addresses(hostname)
    ip_addresses = options.resolver.call(hostname)
    raise SsrfFilter::UnresolvedHostname, "Could not resolve hostname '#{hostname}'" if ip_addresses.empty?

    ip_addresses
  end

  def fetch_once(uri, ip_address, original_uri, &)
    request = build_request(uri)
    strip_sensitive_headers!(request, original_uri, uri)
    validate_request!(request)

    Net::HTTP.start(uri.hostname, uri.port, **http_options(uri, ip_address)) do |http|
      response = http.request(request, &)
      return response, redirect_location(response, uri)
    end
  end

  def build_request(uri)
    request = SsrfFilter::VERB_MAP[options.method].new(uri)
    request['host'] = normalized_hostname(uri)

    Array(options.request_options[:headers]).each { |header, value| request[header] = value }
    request.body = options.body if options.body
    options.request_options[:request_proc].call(request) if options.request_options[:request_proc].respond_to?(:call)

    request
  end

  def http_options(uri, ip_address)
    options.request_options[:http_options].merge(
      use_ssl: uri.scheme == 'https',
      ipaddr: ip_address
    )
  end

  def strip_sensitive_headers!(request, original_uri, uri)
    return unless different_origin?(original_uri, uri)

    options.request_options[:sensitive_headers].each { |header| request.delete(header) }
  end

  def validate_request!(request)
    request.each do |header, value|
      next if header.count("\r\n").zero? && value.count("\r\n").zero?

      raise SsrfFilter::CRLFInjection, "CRLF injection in header #{header} with value #{value}"
    end
  end

  def redirect_location(response, uri)
    return unless response.is_a?(Net::HTTPRedirection)

    location = response['location']
    return "#{uri.scheme}://#{normalized_hostname(uri)}#{location}" if location&.start_with?('/')

    location
  end

  def normalized_hostname(uri)
    return uri.hostname if (uri.port == 80 && uri.scheme == 'http') || (uri.port == 443 && uri.scheme == 'https')

    "#{uri.hostname}:#{uri.port}"
  end

  def different_origin?(uri, other_uri)
    uri.scheme != other_uri.scheme || uri.hostname != other_uri.hostname || uri.port != other_uri.port
  end
end
