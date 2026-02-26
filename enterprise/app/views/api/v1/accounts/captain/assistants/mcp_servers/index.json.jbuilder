json.payload do
  json.array! @assistant_mcp_servers do |assistant_mcp_server|
    json.partial! 'api/v1/models/captain/assistant_mcp_server', assistant_mcp_server: assistant_mcp_server
  end
end

json.meta do
  json.total_count @assistant_mcp_servers.count
  json.page 1
end
