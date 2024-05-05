json.availability_status resource.availability_status
json.email resource.email
json.id resource.id
json.name resource.name
json.phone_number resource.phone_number
json.identifier resource.identifier
json.thumbnail resource.avatar_url
if resource.stage.present?
  json.stage_id resource.id
  json.stage_name resource.stage.name
  json.stage_code resource.stage.code
  json.stage_type resource.stage.stage_type
end
if resource.assignee_in_leads.present?
  json.assignee_id_in_leads resource.assignee_in_leads.id
  json.assignee_name_in_leads resource.assignee_in_leads.name
end
if resource.assignee_in_deals.present?
  json.assignee_id_in_deals resource.assignee_in_deals.id
  json.assignee_name_in_deals resource.assignee_in_deals.name
end
if resource.team.present?
  json.team_id resource.team.id
  json.team_name resource.team.name
end
json.first_reply_created_at resource.first_reply_created_at
json.initial_channel_type resource.initial_channel_type
json.last_stage_changed_at resource.last_stage_changed_at.to_i if resource[:last_stage_changed_at].present?
json.custom_attributes resource.custom_attributes
json.last_activity_at resource.last_activity_at.to_i if resource[:last_activity_at].present?
json.created_at resource.created_at.to_i if resource[:created_at].present?
json.updated_at resource.updated_at.to_i if resource[:updated_at].present?
# we only want to output contact inbox when its /contacts endpoints
if defined?(with_contact_inboxes) && with_contact_inboxes.present?
  json.contact_inboxes do
    json.array! resource.contact_inboxes do |contact_inbox|
      json.partial! 'api/v1/models/contact_inbox', formats: [:json], resource: contact_inbox
    end
  end
end
