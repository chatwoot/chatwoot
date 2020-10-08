json.payload do
  json.array! @workflow_templates do |workflow_template|
    json.id workflow_template.id
    json.name workflow_template.name
    json.description workflow_template.description
  end
end
