live_names = @live_tools.pluck('name')
approved_tools = @mcp_server.tools.index_by(&:name)
json.payload do
  json.array! @live_tools do |tool|
    approved = approved_tools[tool['name']]
    json.name tool['name']
    json.description tool['description']
    json.input_schema tool['input_schema']
    json.read_only tool['read_only']
    json.digest Captain::McpTool.definition_digest(tool)
    json.approved approved.present?
    json.changed approved.present? && !approved.approval_current?(tool)
  end
end
# Approved tools the server no longer offers
json.missing(approved_tools.keys - live_names)
