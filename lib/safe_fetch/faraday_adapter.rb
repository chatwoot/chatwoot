# A Faraday adapter for clients that bring their own HTTP code, such as the RubyLLM MCP client.
# It connects to an address that passed the SafeFetch check, so a hostname cannot point a request at a private network.
class SafeFetch::FaradayAdapter < Faraday::Adapter::NetHttp
  def net_http_connection(env)
    url = env[:url]
    port = url.port || (url.scheme == 'https' ? 443 : 80)
    # No proxy, so the connection goes to the checked address
    Net::HTTP.new(url.hostname, port, nil).tap { |http| http.ipaddr = SafeFetch.safe_address(url.hostname).to_s }
  end
end
