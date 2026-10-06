module McpSpecHelpers
  # Sends one JSON-RPC request to the MCP endpoint and returns its result.
  def mcp_request(method, params, access_token)
    post '/mcp',
         params: { jsonrpc: '2.0', id: 1, method: method, params: params }.to_json,
         headers: { 'Authorization' => "Bearer #{access_token.plaintext_token}", 'Content-Type' => 'application/json',
                    'Accept' => 'application/json, text/event-stream' }
    response.parsed_body['result']
  end

  def call_mcp_tool(name, arguments, access_token)
    mcp_request('tools/call', { name: name, arguments: arguments }, access_token)
  end
end
