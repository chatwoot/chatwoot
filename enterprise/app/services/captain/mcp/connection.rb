# Talks to the MCP server of a Captain::McpServer through the RubyLLM MCP client.
# Every MCP and OAuth request goes through the SafeFetch address checks.
class Captain::Mcp::Connection
  # The longest one read may wait for the server. A server that keeps sending resets it, so DEADLINE bounds the total.
  TIMEOUT = 30
  # The longest one operation may take, however the server spreads its answer. RubyLLM checks it on every chunk it
  # receives, so a server that stops sending is still cut only by TIMEOUT: an operation takes at most DEADLINE plus
  # one TIMEOUT.
  DEADLINE = 30
  # The server answered, but the MCP client could not read the answer
  class InvalidResponse < StandardError; end
  # A CancelledError, so RubyLLM tells a server on an older MCP revision that Captain stopped waiting. On the current
  # revision the closed stream tells it.
  class DeadlineExceeded < RubyLLM::CancelledError; end

  # The server or the network failed: a bad answer, a refused address or a lost connection. Callers handle these as
  # expected failures, and anything else is a bug that should reach Sentry.
  ERRORS = [RubyLLM::Error, SafeFetch::Error, Faraday::Error, InvalidResponse, DeadlineExceeded,
            Captain::Mcp::SafeFaradayAdapter::ResponseTooLarge].freeze

  def self.oauth_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', '')}/captain/mcp/callback"
  end

  def initialize(server)
    @server = server
  end

  # Runs a request with the saved credentials and records what it says about them. A 401 means the server rejected the
  # credentials. Any other failure says only that this request failed.
  def track_status
    result = yield
    @server.credentials_accepted!
    result
  rescue *ERRORS => e
    e.is_a?(RubyLLM::UnauthorizedError) ? @server.credentials_rejected! : @server.record_request_error(e.message)
    raise
  end

  # Tools the server offers to models, as the definitions Captain approves and compares.
  # A reply the MCP client cannot parse, such as a string where it expects an object, raises InvalidResponse, so one
  # server's bad reply is handled like a failed request and never stops a run. The original error is logged, not sent
  # to Sentry, because a broken server would report it on every listing.
  def tool_definitions
    within_deadline do
      mcp.tools.select { |tool| tool.visibility.include?(:model) }.map do |tool|
        {
          'name' => tool.server_name,
          'description' => tool.description,
          'input_schema' => tool.parameters_schema,
          'read_only' => tool.read_only?
        }
      end
    end
  rescue *ERRORS
    raise
  rescue StandardError => e
    Rails.logger.warn("Captain MCP server #{@server.id} sent a tool list Captain could not read: #{e.class} - #{e.message}")
    raise InvalidResponse, "The server sent a tool list Captain could not read (#{e.class})"
  end

  # Lists the server with the saved credentials and records what the request says about them. RubyLLM keeps the
  # listing for the life of this connection, so a run that calls several tools on one server lists it once.
  #
  # Known limit: while a server is slow, a listing and a call each wait up to DEADLINE plus one TIMEOUT and hold a
  # Sidekiq thread meanwhile. Only a run that calls one of the server's tools pays this. The MCP session is never closed.
  def live_tool_definitions
    track_status { tool_definitions }
  end

  # RubyLLM exposes the server's name only through its private server info
  def server_name
    within_deadline { mcp.send(:server_info)['name'] }
  end

  def call(server_tool_name, arguments)
    within_deadline { mcp.call(server_tool_name, **arguments) }
  end

  def authorization_url
    url = within_deadline { mcp.authorization_url(redirect_uri: self.class.oauth_redirect_uri) }
    @server.remember_oauth_state(Rack::Utils.parse_query(URI(url).query)['state'])
    url
  end

  def authorize(params)
    within_deadline { mcp.authorize(params) }
  end

  def mcp
    @mcp ||= context.mcp(url: @server.url, name: "#{Captain::McpServer::TOOL_NAME_PREFIX}_#{@server.id}",
                         timeout: TIMEOUT, **auth_settings)
  end

  private

  def within_deadline(&)
    RubyLLM::Support::Cancellation.watch(deadline_checkpoint, &)
  end

  # RubyLLM keeps one checkpoint per thread, so this one also runs the checkpoint it replaces, such as a chat's
  # cancellation
  def deadline_checkpoint
    deadline = DEADLINE.seconds.from_now
    previous = Thread.current[RubyLLM::Support::Cancellation::KEY]
    lambda do
      previous&.call
      raise DeadlineExceeded, "#{URI(@server.url).host} did not finish within #{DEADLINE} seconds" if Time.current > deadline
    end
  end

  # Each server has its own context, because RubyLLM reads the credential store from the context config
  def context
    RubyLLM.context do |config|
      config.faraday_adapter = Captain::Mcp::SafeFaradayAdapter
      config.mcp_credential_store = Captain::Mcp::CredentialStore.new(@server)
      config.mcp_client_name = GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot')
    end
  end

  def auth_settings
    case @server.auth_type
    when 'oauth' then { oauth: { owner: @server } }
    when 'token' then token_settings
    else {}
    end
  end

  def token_settings
    token = @server.auth_config['token']
    @server.auth_header ? { headers: { @server.auth_header => token } } : { bearer_token: token }
  end
end
