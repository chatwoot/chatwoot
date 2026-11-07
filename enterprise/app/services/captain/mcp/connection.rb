# Talks to the MCP server of a Captain::McpServer through the RubyLLM MCP client.
# Every MCP and OAuth request goes through the SafeFetch address checks.
class Captain::Mcp::Connection
  TIMEOUT = 30
  # A run or the hourly check reuses a listing for this long, so a burst of messages lists each server once
  LISTING_TTL = 1.minute
  # The server answered, but the MCP client could not read the answer
  class InvalidResponse < StandardError; end

  # The server or the network failed: a bad answer, a refused address or a lost connection. Callers handle these as
  # expected failures, and anything else is a bug that should reach Sentry.
  ERRORS = [RubyLLM::Error, SafeFetch::Error, Faraday::Error, InvalidResponse].freeze

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
    mcp.tools.select { |tool| tool.visibility.include?(:model) }.map do |tool|
      {
        'name' => tool.server_name,
        'description' => tool.description,
        'input_schema' => tool.parameters_schema,
        'read_only' => tool.read_only?
      }
    end
  rescue *ERRORS
    raise
  rescue StandardError => e
    Rails.logger.warn("Captain MCP server #{@server.id} sent a tool list Captain could not read: #{e.class} - #{e.message}")
    raise InvalidResponse, "The server sent a tool list Captain could not read (#{e.class})"
  end

  # The tool definitions for a run or the hourly check, reused for LISTING_TTL. The tools page and approval list the
  # server live, because an admin compares what it offers now. A failed listing is not kept, so the next run tries again.
  #
  # Known limit: while a server hangs, every run waits for the timeouts (about 40 seconds, RubyLLM's 10 second discovery
  # plus TIMEOUT) before it skips the server, and holds a Sidekiq thread meanwhile. Runs also list servers that need new
  # credentials, and the MCP session is never closed. A short Redis mark after a failed listing, skipping needs_credentials
  # servers in Captain::Mcp::AgentTools, and closing the connections after a run would remove these costs.
  def recent_tool_definitions
    key = format(::Redis::RedisKeys::CAPTAIN_MCP_TOOL_LISTING, server_id: @server.id)
    cached = ::Redis::Alfred.get(key)
    return JSON.parse(cached) if cached

    track_status { tool_definitions }.tap { |definitions| ::Redis::Alfred.setex(key, definitions.to_json, LISTING_TTL) }
  end

  # RubyLLM exposes the server's name only through its private server info
  def server_name
    mcp.send(:server_info)['name']
  end

  def call(server_tool_name, arguments)
    mcp.call(server_tool_name, **arguments)
  end

  def authorization_url
    url = mcp.authorization_url(redirect_uri: self.class.oauth_redirect_uri)
    @server.remember_oauth_state(Rack::Utils.parse_query(URI(url).query)['state'])
    url
  end

  def authorize(params)
    mcp.authorize(params)
  end

  def mcp
    @mcp ||= context.mcp(url: @server.url, name: "#{Captain::McpServer::TOOL_NAME_PREFIX}_#{@server.id}",
                         timeout: TIMEOUT, **auth_settings)
  end

  private

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
