json.account_id resource.account_id
json.answer resource.answer
json.assistant do
  json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: resource.assistant
end
json.created_at resource.created_at.to_i
if resource.document
  json.document do
    json.id resource.document.id
    json.external_link resource.document.external_link
    json.name resource.document.name
  end
end
json.id resource.id
json.question resource.question
json.updated_at resource.updated_at.to_i
