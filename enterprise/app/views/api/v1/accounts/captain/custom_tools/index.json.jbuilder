json.payload do
  json.array! @custom_tools do |custom_tool|
    json.partial! 'api/v1/models/captain/custom_tool', custom_tool: custom_tool
  end
end

json.meta do
  json.total_count @custom_tools.count
  json.page 1
end
