json.id mcp_server.id
json.account_id mcp_server.account_id
json.assistant_id mcp_server.assistant_id
json.url mcp_server.url
json.name mcp_server.name
json.auth_type mcp_server.auth_type
json.auth_header mcp_server.auth_header
# The token itself never leaves the server
json.has_token mcp_server.auth_config['token'].present?
json.server_info mcp_server.server_info
json.status mcp_server.status
json.last_checked_at mcp_server.last_checked_at&.to_i
json.last_error mcp_server.last_error
json.tools_changed_at mcp_server.tools_changed_at&.to_i
json.enabled mcp_server.enabled
json.tools mcp_server.tools do |tool|
  json.name tool['name']
  json.captain_tool_name mcp_server.captain_tool_name(tool['name'])
  json.description tool.dig('approved_definition', 'description')
  json.input_schema tool.dig('approved_definition', 'input_schema')
  json.approved_digest tool['approved_digest']
  json.param_sources tool['param_sources']
  json.settings tool['settings']
  json.requires_email_verification Captain::McpServer.requires_email_verification?(tool)
  json.enabled tool['enabled']
end
json.created_at mcp_server.created_at.to_i
json.updated_at mcp_server.updated_at.to_i
