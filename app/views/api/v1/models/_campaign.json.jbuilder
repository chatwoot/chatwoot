json.id resource.display_id
json.title resource.title
json.description resource.description
json.account_id resource.account_id
json.inbox do
  json.partial! 'api/v1/models/inbox', formats: [:json], resource: resource.inbox
end
json.sender do
  json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.sender if resource.sender.present?
end
json.message resource.message
json.campaign_status resource.campaign_status
json.enabled resource.enabled
json.campaign_type resource.campaign_type
if resource.campaign_type == 'one_off'
  json.scheduled_at resource.scheduled_at.to_i
  json.audience resource.audience
end
json.trigger_rules resource.trigger_rules
json.trigger_only_during_business_hours resource.trigger_only_during_business_hours
json.created_at resource.created_at
json.updated_at resource.updated_at
