# Protected resource metadata, as defined in RFC 9728.
class Mcp::MetadataController < ApplicationController
  def show
    base_url = ENV.fetch('FRONTEND_URL')

    render json: {
      resource: "#{base_url}/mcp",
      authorization_servers: [base_url],
      scopes_supported: Mcp::Tools::ALL.map(&:required_scope).uniq,
      bearer_methods_supported: ['header']
    }
  end
end
