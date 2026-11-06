# RubyLLM sends every MCP and OAuth request through Faraday, including requests to OAuth endpoints the remote server
# names. This adapter connects each one only to an address that passes the same check SafeFetch.fetch applies.
# It connects to the address it checked, so a hostname cannot resolve to a public address for the check and a private
# one for the connection. The hostname stays on the request, so HTTPS still verifies the server's certificate.
class Captain::Mcp::SafeFaradayAdapter < Faraday::Adapter::NetHttp
  def net_http_connection(env)
    url = env[:url]
    port = url.port || (url.scheme == 'https' ? 443 : 80)
    # No proxy, so the connection goes to the checked address
    Net::HTTP.new(url.hostname, port, nil).tap { |http| http.ipaddr = safe_address(url.hostname).to_s }
  end

  private

  # ssrf_filter keeps its address check private, but it is the same check SafeFetch.fetch applies
  def safe_address(hostname)
    addresses = SsrfFilter::DEFAULT_RESOLVER.call(hostname)
    addresses = addresses.reject { |address| SsrfFilter.send(:unsafe_ip_address?, address) } unless SafeFetch.allow_private_network?
    addresses.sample || raise(SafeFetch::UnsafeUrlError, "#{hostname} does not resolve to a public address")
  end
end
