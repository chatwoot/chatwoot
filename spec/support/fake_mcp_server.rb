# A small MCP server for specs, served through WebMock's to_rack, so the RubyLLM client talks to it over real HTTP
# messages without a network. It speaks the 2026-07-28 revision, which RubyLLM tries first, so it answers
# server/discover, tools/list and tools/call. A call answers with the tool's name. A spec changes its tools, its sign-in
# and its failures between requests.
class FakeMcpServer
  VERSION = '2026-07-28'.freeze
  METHOD_NOT_FOUND = -32_601
  RESOURCE_METADATA = 'https://mcp.example.com/.well-known/oauth-protected-resource'.freeze

  # token: the token a request must carry, nil for none. auth_header: the header that carries it, nil for Bearer.
  # rejects: answer every request with 401. oauth_challenge: the 401 names OAuth metadata. fails: answer 500.
  attr_accessor :tools, :token, :auth_header, :rejects, :oauth_challenge, :fails

  def initialize(name: 'Invoicely')
    @name = name
    @tools = []
  end

  def call(env)
    return [500, { 'Content-Type' => 'application/json' }, ['{}']] if fails
    return unauthorized if rejects || !authorized?(env)

    message = JSON.parse(env['rack.input'].read)
    # Notifications have no id and need no answer
    return [202, {}, []] unless message['id']

    answer(message)
  end

  private

  def authorized?(env)
    return true if token.nil?

    header = auth_header ? "HTTP_#{auth_header.upcase.tr('-', '_')}" : 'HTTP_AUTHORIZATION'
    env[header] == (auth_header ? token : "Bearer #{token}")
  end

  def unauthorized
    challenge = oauth_challenge ? %(Bearer resource_metadata="#{RESOURCE_METADATA}") : 'Bearer'
    [401, { 'Content-Type' => 'application/json', 'WWW-Authenticate' => challenge }, ['{}']]
  end

  def answer(message)
    result = case message['method']
             when 'server/discover' then { supportedVersions: [VERSION], serverInfo: { name: @name, version: '1.0' }, capabilities: { tools: {} } }
             when 'tools/list' then { tools: tools }
             when 'tools/call' then { content: [{ type: 'text', text: "Called #{message.dig('params', 'name')}" }] }
             end
    body = result ? { result: result } : { error: { code: METHOD_NOT_FOUND, message: 'Method not found' } }
    [200, { 'Content-Type' => 'application/json' }, [JSON.generate(body.merge(jsonrpc: '2.0', id: message['id']))]]
  end
end
