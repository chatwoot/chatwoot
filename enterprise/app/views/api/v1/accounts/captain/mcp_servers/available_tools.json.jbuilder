live_names = @live_tools.pluck('name')
json.payload do
  json.array! @live_tools do |tool|
    approved = @mcp_server.approved_tool(tool['name'])
    json.name tool['name']
    json.description tool['description']
    json.input_schema tool['input_schema']
    json.read_only tool['read_only']
    json.digest Captain::McpServer.definition_digest(tool)
    json.approved approved.present?
    json.changed approved.present? && approved['approved_digest'] != Captain::McpServer.definition_digest(tool)
  end
end
# Approved tools the server no longer offers
json.missing(@mcp_server.tools.pluck('name') - live_names)
