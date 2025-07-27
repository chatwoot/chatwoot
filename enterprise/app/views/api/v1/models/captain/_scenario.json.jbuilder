json.id scenario.id
json.title scenario.title
json.description scenario.description
json.instruction scenario.instruction
json.tools scenario.tools
json.enabled scenario.enabled
json.assistant_id scenario.assistant_id
json.account_id scenario.account_id
json.created_at scenario.created_at
json.updated_at scenario.updated_at
if scenario.assistant.present?
  json.assistant do
    json.id scenario.assistant.id
    json.name scenario.assistant.name
  end
end
