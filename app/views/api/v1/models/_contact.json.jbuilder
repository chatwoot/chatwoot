json.availability_status resource.availability_status
json.email resource.email
json.id resource.id
json.name resource.name
json.phone_number resource.phone_number
json.identifier resource.identifier
json.thumbnail resource.avatar_url
json.stage resource.stage if resource.stage.present?
json.assignee resource.assignee if resource.assignee.present?
json.team resource.team if resource.team.present?
json.last_note resource.notes.order(created_at: :desc).first.content if resource.notes.present?
json.first_reply_created_at resource.first_reply_created_at
json.initial_channel_type resource.initial_channel_type
json.last_stage_changed_at resource.last_stage_changed_at.to_i if resource[:last_stage_changed_at].present?
json.product resource.product if resource.product.present?
json.po_date resource.po_date
json.po_value resource.po_value
json.po_note resource.po_note
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
json.conversation_plans do
  json.array! resource.conversation_plans.latest do |conversation_plan|
    json.partial! 'api/v1/conversations/partials/conversation_plan', formats: [:json], resource: conversation_plan
  end
end
