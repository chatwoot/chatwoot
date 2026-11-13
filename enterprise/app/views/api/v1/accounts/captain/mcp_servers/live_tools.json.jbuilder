comparison = @mcp_server.live_tool_entries(@live_tools)
json.payload do
  json.array! comparison[:tools] do |entry|
    tool = entry[:definition]
    json.name tool['name']
    json.description tool['description']
    json.input_schema tool['input_schema']
    json.read_only tool['read_only']
    json.digest Captain::McpTool.definition_digest(tool)
    json.approved entry[:approved]
    json.changed entry[:changed]
  end
end
# Approved tools the server no longer offers
json.missing comparison[:missing]
