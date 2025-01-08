json.account_id resource.account_id
json.answer resource.answer
json.created_at resource.created_at.to_i
json.id resource.id
json.question resource.question
json.assistant do
  json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: resource.assistant
end
if resource.document
  json.document do
    json.id resource.document.id
    json.external_link resource.document.external_link
    json.name resource.document.name
  end
end
