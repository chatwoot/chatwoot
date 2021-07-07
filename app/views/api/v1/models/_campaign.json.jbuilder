json.id resource.display_id
json.title resource.title
json.description resource.description
json.account_id resource.account_id
json.inbox do
  json.partial! 'api/v1/models/inbox.json.jbuilder', resource: resource.inbox
end
json.sender do
  json.partial! 'api/v1/models/agent.json.jbuilder', resource: resource.sender if resource.sender.present?
end
json.message resource.message
json.enabled resource.enabled
json.campaign_type resource.campaign_type
if resource.campaign_type == 'one_off'
  json.trigger_time resource.trigger_time
  json.audience resource.audience
end
json.locked resource.locked
json.trigger_rules resource.trigger_rules
json.created_at resource.created_at
json.updated_at resource.updated_at
