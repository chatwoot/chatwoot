json.payload do
  json.array! @mcp_servers do |mcp_server|
    json.partial! 'api/v1/models/captain/mcp_server', mcp_server: mcp_server
  end
end

json.meta do
  json.total_count @mcp_servers.count
  json.page 1
end
