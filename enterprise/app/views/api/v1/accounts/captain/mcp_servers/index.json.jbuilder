json.payload do
  json.array! @mcp_servers do |mcp_server|
    json.partial! 'api/v1/models/captain/mcp_server', mcp_server: mcp_server
  end
end
