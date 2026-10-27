# Checks an MCP server URL before it is saved: which sign-in the server wants, and its name.
# The tools are listed later, when the admin picks them.
# Without a token, a server that answers 401 needs OAuth if it publishes OAuth metadata, and a token otherwise.
class Captain::Mcp::DiscoveryService
  Result = Data.define(:auth_type, :name)
  InvalidUrlError = Class.new(StandardError)
  # Where a server that sends no resource_metadata in its 401 can still publish OAuth metadata:
  # - Protected resource metadata (RFC 9728) at a .well-known path, which newer MCP revisions allow.
  # - Authorization server metadata (RFC 8414) at the server's origin, as servers from the 2025-03-26 revision do.
  # RubyLLM signs in to both kinds, so a server found here can use OAuth.
  OAUTH_METADATA_PATHS = ['/.well-known/oauth-protected-resource%<path>s', '/.well-known/oauth-authorization-server'].freeze
  MAX_METADATA_BYTES = 64.kilobytes

  def initialize(url:, token: nil, auth_header: nil)
    @url = url
    @token = token
    @auth_header = auth_header
  end

  def perform
    validate_url!
    connection = Captain::Mcp::Connection.new(probe_server)
    Result.new(auth_type: probe_server.auth_type, name: connection.server_name.presence || host)
  rescue RubyLLM::UnauthorizedError => e
    raise if @token.present?

    Result.new(auth_type: oauth?(e.response) ? 'oauth' : 'token', name: host)
  end

  private

  # The URL gets the same check as a saved server before Chatwoot connects to it. Only URL errors count, because
  # the probe has no name, account or assistant.
  def validate_url!
    probe_server.validate
    url_errors = probe_server.errors.full_messages_for(:endpoint_url)
    raise InvalidUrlError, url_errors.to_sentence if url_errors.any?
  end

  def probe_server
    @probe_server ||= Captain::McpServer.new(url: @url, auth_type: @token.present? ? 'token' : 'none',
                                             auth_header: @auth_header.presence, auth_config: { 'token' => @token })
  end

  # The resource_metadata challenge is enough when the server sends it. Without it, the paths above are probed, so a
  # server that wants OAuth is not reported as needing a token, which the admin would not have. Each probe goes through
  # SafeFetch and reads at most MAX_METADATA_BYTES, and probes run only on discover, after a 401 without the challenge.
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
