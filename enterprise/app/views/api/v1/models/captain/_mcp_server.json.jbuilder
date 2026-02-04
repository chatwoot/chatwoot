json.id mcp_server.id
json.slug mcp_server.slug
json.name mcp_server.name
json.description mcp_server.description
json.url mcp_server.url
json.auth_type mcp_server.auth_type
json.auth_config do
  auth_config = mcp_server.auth_config || {}
  case mcp_server.auth_type
  when 'bearer'
    json.has_token auth_config['token'].present?
  when 'api_key'
    json.has_key auth_config['key'].present?
    json.header_name auth_config['header_name']
  end
  json.transport auth_config['transport']
  json.rpc_endpoint auth_config['rpc_endpoint']
end
json.enabled mcp_server.enabled
json.status mcp_server.status
json.last_error mcp_server.last_error
json.last_connected_at mcp_server.last_connected_at&.to_i
json.cached_tools mcp_server.cached_tools
json.cache_refreshed_at mcp_server.cache_refreshed_at&.to_i
json.account_id mcp_server.account_id
json.created_at mcp_server.created_at.to_i
json.updated_at mcp_server.updated_at.to_i
