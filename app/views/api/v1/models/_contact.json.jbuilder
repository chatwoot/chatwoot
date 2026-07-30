json.additional_attributes resource.additional_attributes
json.availability_status resource.availability_status
json.email resource.email
json.id resource.id
json.name resource.name
json.phone_number resource.phone_number
json.blocked resource.blocked
json.identifier resource.identifier
json.document_number resource.document_number
json.company_id resource.company_id if Current.account&.feature_enabled?('companies')
json.thumbnail resource.avatar_url
json.custom_attributes resource.custom_attributes
json.assigned_agent_id resource.assigned_agent_id
json.assigned_agent resource.assigned_agent&.push_event_data
json.chat_bot resource.chat_bot
json.labels @contact_labels_by_id.fetch(resource.id, []) if @contact_labels_by_id
json.last_activity_at resource.last_activity_at.to_i if resource[:last_activity_at].present?
json.created_at resource.created_at.to_i if resource[:created_at].present?
# we only want to output contact inbox when its /contacts endpoints
if defined?(with_contact_inboxes) && with_contact_inboxes.present?
  json.contact_inboxes do
    json.array! resource.contact_inboxes do |contact_inbox|
      json.partial! 'api/v1/models/contact_inbox', formats: [:json], resource: contact_inbox
    end
  end
end
