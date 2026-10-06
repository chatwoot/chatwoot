# Protected resource metadata, as defined in RFC 9728.
class Mcp::MetadataController < ApplicationController
  def show
    base_url = ENV.fetch('FRONTEND_URL')

    render json: {
      resource: "#{base_url}/mcp",
      authorization_servers: [base_url],
      scopes_supported: Doorkeeper.config.scopes.to_a,
      bearer_methods_supported: ['header']
    }
  end
end
