json.id assistant_mcp_server.id
json.captain_assistant_id assistant_mcp_server.captain_assistant_id
json.captain_mcp_server_id assistant_mcp_server.captain_mcp_server_id
json.tool_filters assistant_mcp_server.tool_filters
json.enabled assistant_mcp_server.enabled
json.created_at assistant_mcp_server.created_at.to_i
json.updated_at assistant_mcp_server.updated_at.to_i

json.mcp_server do
  json.partial! 'api/v1/models/captain/mcp_server', mcp_server: assistant_mcp_server.mcp_server
end
