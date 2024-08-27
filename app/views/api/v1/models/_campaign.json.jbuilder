json.id resource.display_id
json.title resource.title
json.description resource.description
json.account_id resource.account_id
json.inbox do
  json.partial! 'api/v1/models/inbox', formats: [:json], resource: resource.inbox if resource.inbox.present?
end
json.sender do
  json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.sender if resource.sender.present?
end
json.message resource.message
json.private_note resource.private_note
json.campaign_status resource.campaign_status
json.enabled resource.enabled
json.planned resource.planned
json.campaign_type resource.campaign_type
json.scheduled_at resource.scheduled_at if resource.campaign_type == 'one_off'
json.flexible_scheduled_at resource.flexible_scheduled_at if resource.campaign_type == 'flexible'
if resource.campaign_type == 'one_off' || resource.campaign_type == 'flexible'
  json.audience resource.audience
  json.inboxes resource.inboxes
end
json.trigger_rules resource.trigger_rules
json.trigger_only_during_business_hours resource.trigger_only_during_business_hours
json.created_at resource.created_at
json.updated_at resource.updated_at
