# Builds the Bearer challenge that tells an MCP client where to start, or extend, the OAuth flow.
module Mcp::BearerChallenge
  def self.build(**params)
    params = { resource_metadata: "#{ENV.fetch('FRONTEND_URL')}/.well-known/oauth-protected-resource/mcp" }.merge(params)

    "Bearer #{params.map { |key, value| %(#{key}="#{value}") }.join(', ')}"
  end
end
