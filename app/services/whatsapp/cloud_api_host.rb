# Dualhook is Graph-compatible at api.dualhook.com/v25.0 and requires dh_live_ keys.
# Unsigned Graph calls via Dualhook's Meta app are declined (appsecret_proof).
module Whatsapp::CloudApiHost
  DUALHOOK_BASE = 'https://api.dualhook.com'.freeze
  GRAPH_BASE = 'https://graph.facebook.com'.freeze
  DUALHOOK_VERSION = 'v25.0'.freeze

  module_function

  def dualhook_key?(api_key)
    api_key.to_s.start_with?('dh_live_', 'dh_test_')
  end

  def base_url(api_key)
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', dualhook_key?(api_key) ? DUALHOOK_BASE : GRAPH_BASE)
  end

  def dualhook_host?(api_key)
    host_of(base_url(api_key)) == 'api.dualhook.com'
  end

  def api_version(api_key, legacy)
    dualhook_host?(api_key) ? DUALHOOK_VERSION : legacy
  end

  def host_of(url)
    URI.parse(url).host
  rescue URI::InvalidURIError
    url.to_s
  end
end
