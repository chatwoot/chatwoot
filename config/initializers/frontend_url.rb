# frozen_string_literal: true

# Parse FRONTEND_URL (full URL) into Rails default_url_options components.
module FrontendUrl
  module_function

  def default_url_options
    frontend = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    uri = URI.parse(frontend)
    opts = { host: uri.host, protocol: uri.scheme }
    opts[:port] = uri.port if uri.port && [80, 443].exclude?(uri.port)
    opts
  end
end
