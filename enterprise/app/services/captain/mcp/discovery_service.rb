# Checks an MCP server URL before it is saved: which sign-in the server wants, its name, and its tools.
# Without a token, a server that answers 401 needs OAuth if it publishes OAuth metadata, and a token otherwise.
class Captain::Mcp::DiscoveryService
  Result = Data.define(:auth_type, :name, :version, :tools)
  OAUTH_METADATA_PATHS = ['/.well-known/oauth-protected-resource%<path>s', '/.well-known/oauth-authorization-server'].freeze
  MAX_METADATA_BYTES = 64.kilobytes

  def initialize(url:, token: nil, auth_header: nil)
    @url = url
    @token = token
    @auth_header = auth_header
  end

  def perform
    connection = Captain::Mcp::Connection.new(probe_server)
    Result.new(auth_type: probe_server.auth_type, name: connection.server_name.presence || host,
               version: connection.server_version, tools: connection.tool_definitions)
  rescue RubyLLM::UnauthorizedError => e
    raise if @token.present?

    Result.new(auth_type: oauth?(e.response) ? 'oauth' : 'token', name: host, version: nil, tools: nil)
  end

  private

  def probe_server
    @probe_server ||= Captain::McpServer.new(url: @url, auth_type: @token.present? ? 'token' : 'none',
                                             auth_header: @auth_header.presence, auth_config: { 'token' => @token })
  end

  def oauth?(response)
    challenge = response&.headers&.fetch('www-authenticate', nil)
    return true if challenge.to_s.include?('resource_metadata')

    path = URI(@url).path.chomp('/')
    OAUTH_METADATA_PATHS.any? { |metadata_path| metadata?(URI.join(@url, format(metadata_path, path: path)).to_s) }
  end

  def metadata?(url)
    SafeFetch.fetch(url, validate_content_type: false, max_bytes: MAX_METADATA_BYTES) { |result| JSON.parse(result.tempfile.read) }
    true
  rescue SafeFetch::Error, JSON::ParserError
    false
  end

  def host
    URI(@url).host
  end
end
