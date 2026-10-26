# Talks to the MCP server of a Captain::McpServer through the RubyLLM MCP client.
# Every MCP and OAuth request goes through the SafeFetch address checks.
class Captain::Mcp::Connection
  TIMEOUT = 30
  # Matches how long RubyLLM keeps a pending OAuth sign-in
  OAUTH_STATE_TTL = 10.minutes

  def self.context
    @context ||= RubyLLM.context do |config|
      config.faraday_adapter = SafeFetch::FaradayAdapter
      config.mcp_client_name = GlobalConfigService.load('INSTALLATION_NAME', 'Chatwoot')
    end
  end

  def self.oauth_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', '')}/captain/mcp/callback"
  end

  # Returns the server an OAuth sign-in with this state started for, once
  def self.server_for_oauth_state(state)
    key = format(::Redis::RedisKeys::CAPTAIN_MCP_OAUTH_STATE, state: state.to_s)
    server_id = ::Redis::Alfred.get(key)
    ::Redis::Alfred.delete(key)
    Captain::McpServer.find_by(id: server_id) if server_id
  end

  ERRORS = [RubyLLM::Error, SafeFetch::Error, Faraday::Error].freeze

  def initialize(server)
    @server = server
  end

  # Runs a request and records the result on the server. Status columns skip the lock, so a check never conflicts with an admin edit.
  def track_status
    result = yield
    @server.update_columns(status: :active, last_checked_at: Time.current, last_error: nil, # rubocop:disable Rails/SkipsModelValidations
                           server_info: { 'name' => server_name, 'version' => server_version }.compact)
    result
  rescue *ERRORS => e
    status = e.is_a?(RubyLLM::UnauthorizedError) ? :needs_sign_in : :error
    @server.update_columns(status: status, last_checked_at: Time.current, last_error: e.message) # rubocop:disable Rails/SkipsModelValidations
    raise
  end

  # Tools the server offers to models, as the definitions Captain approves and compares
  def tool_definitions
    mcp.tools.select { |tool| tool.visibility.include?(:model) }.map do |tool|
      {
        'name' => tool.server_name,
        'description' => tool.description,
        'input_schema' => tool.parameters_schema,
        'read_only' => tool.read_only?
      }
    end
  end

  # RubyLLM exposes the server's name only through its private server info
  def server_name
    mcp.send(:server_info)['name']
  end

  def server_version
    mcp.version
  end

  def call(server_tool_name, arguments)
    mcp.call(server_tool_name, **arguments)
  end

  def authorization_url
    url = mcp.authorization_url(redirect_uri: self.class.oauth_redirect_uri)
    state = Rack::Utils.parse_query(URI(url).query)['state']
    ::Redis::Alfred.setex(format(::Redis::RedisKeys::CAPTAIN_MCP_OAUTH_STATE, state: state), @server.id, OAUTH_STATE_TTL)
    url
  end

  def authorize(params)
    mcp.authorize(params)
  end

  def mcp
    @mcp ||= self.class.context.mcp(url: @server.url, name: "#{Captain::McpServer::TOOL_NAME_PREFIX}_#{@server.id}",
                                    timeout: TIMEOUT, **auth_settings)
  end

  private

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
