json.payload do
  json.array! @mcp_servers do |mcp_server|
    json.partial! 'api/v1/models/captain/mcp_server', mcp_server: mcp_server
  end
end

json.meta do
  json.total_count @mcp_servers.total_count
  json.current_page @mcp_servers.current_page
  json.per_page @mcp_servers.limit_value
  json.total_pages @mcp_servers.total_pages
end
