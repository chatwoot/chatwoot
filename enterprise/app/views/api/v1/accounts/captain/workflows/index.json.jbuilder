json.payload do
  json.array! @workflows do |workflow|
    json.partial! 'api/v1/models/captain/workflow', workflow: workflow
  end
end

json.meta do
  json.total_count @workflows.count
  json.page 1
end
