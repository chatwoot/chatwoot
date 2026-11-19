# RubyLLM sends every MCP and OAuth request through Faraday, including requests to OAuth endpoints the remote server
# names. This adapter connects each one only to an address that passes the same check SafeFetch.fetch applies.
# It connects to the address it checked, so a hostname cannot resolve to a public address for the check and a private
# one for the connection. The hostname stays on the request, so HTTPS still verifies the server's certificate.
class Captain::Mcp::SafeFaradayAdapter < Faraday::Adapter::NetHttp
  # The most bytes one MCP response may carry. RubyLLM reads every MCP response in chunks and keeps them until the
  # answer is complete, so the read stops here instead of after the whole response is in memory.
  MAX_RESPONSE_BYTES = 2.megabytes

  class ResponseTooLarge < StandardError; end

  def net_http_connection(env)
    url = env[:url]
    port = url.port || (url.scheme == 'https' ? 443 : 80)
    # No proxy, so the connection goes to the checked address
    Net::HTTP.new(url.hostname, port, nil).tap { |http| http.ipaddr = safe_address(url.hostname).to_s }
  end

  def perform_request(http, env)
    limit_response_size(env) if env.stream_response?
    super
  end

  private

  # Faraday passes each chunk to on_data with the bytes received so far
  def limit_response_size(env)
    on_data = env.request.on_data
    env.request.on_data = lambda do |chunk, received, response_env|
      raise ResponseTooLarge, "#{env[:url].host} sent more than #{MAX_RESPONSE_BYTES} bytes" if received > MAX_RESPONSE_BYTES

      on_data.call(chunk, received, response_env)
    end
  end

  # ssrf_filter keeps its address check private, but it is the same check SafeFetch.fetch applies
  def safe_address(hostname)
    addresses = SsrfFilter::DEFAULT_RESOLVER.call(hostname)
    addresses = addresses.reject { |address| SsrfFilter.send(:unsafe_ip_address?, address) } unless SafeFetch.allow_private_network?
    addresses.sample || raise(SafeFetch::UnsafeUrlError, "#{hostname} does not resolve to a public address")
  end
end
