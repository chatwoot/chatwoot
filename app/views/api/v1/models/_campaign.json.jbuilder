json.id resource.display_id
json.content resource.content
json.description resource.description
json.enabled resource.enabled
json.title resource.title
json.trigger_rules resource.trigger_rules
json.account_id resource.account_id
json.inbox do
  json.partial! 'api/v1/models/inbox.json.jbuilder', resource: resource.inbox
end
json.sender do
  json.partial! 'api/v1/models/agent.json.jbuilder', resource: resource.sender if resource.sender.present?
end
json.created_at resource.created_at
json.updated_at resource.updated_at
