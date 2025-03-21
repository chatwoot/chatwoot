# TODO: Move this into models jbuilder
# Currently the file there is used only for search endpoint.
# Everywhere else we use conversation builder in partials folder

json.meta do
  json.sender do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: conversation.contact
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assignee&.account
    json.assignee do
      json.partial! 'api/v1/models/agent', formats: [:json], resource: conversation.assignee
    end
  end
  if conversation.team.present?
    json.team do
      json.partial! 'api/v1/models/team', formats: [:json], resource: conversation.team
    end
  end
  json.hmac_verified conversation.contact_inbox&.hmac_verified
end

json.id conversation.display_id

if conversation.respond_to?(:preloaded_last_message) && conversation.preloaded_last_message.present?
  message_data = conversation.preloaded_last_message.try(:push_event_data)
  json.messages message_data ? [message_data] : []
elsif conversation.messages.where(account_id: conversation.account_id).last.blank?
  json.messages []
else
  message = conversation.messages.where(account_id: conversation.account_id)
                        .includes([{ attachments: [{ file_attachment: [:blob] }] }]).last
  message_data = message.try(:push_event_data)
  json.messages message_data ? [message_data] : []
end

json.account_id conversation.account_id
json.uuid conversation.uuid
json.additional_attributes conversation.additional_attributes
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.assignee_last_seen_at conversation.assignee_last_seen_at.to_i
json.can_reply conversation.can_reply?
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.custom_attributes conversation.custom_attributes
json.inbox_id conversation.inbox_id
json.labels conversation.cached_label_list_array
json.muted conversation.muted?
json.snoozed_until conversation.snoozed_until
json.status conversation.status
json.created_at conversation.created_at.to_i
json.updated_at conversation.updated_at.to_f
json.timestamp conversation.last_activity_at.to_i
json.first_reply_created_at conversation.first_reply_created_at.to_i

# Use the preloaded unread count if available
json.unread_count conversation.respond_to?(:preloaded_unread_count) ? conversation.preloaded_unread_count : conversation.unread_incoming_messages.count

# Use the preloaded last non-activity message if available
message_data = nil
if conversation.respond_to?(:preloaded_last_non_activity_message) && conversation.preloaded_last_non_activity_message.present?
  message_data = conversation.preloaded_last_non_activity_message.try(:push_event_data)
else
  non_activity_message = conversation.messages.where(account_id: conversation.account_id).non_activity_messages.first
  message_data = non_activity_message.try(:push_event_data) if non_activity_message
end
json.last_non_activity_message message_data

json.last_activity_at conversation.last_activity_at.to_i
json.priority conversation.priority
json.waiting_since conversation.waiting_since.to_i.to_i
json.sla_policy_id conversation.sla_policy_id
json.partial! 'enterprise/api/v1/conversations/partials/conversation', conversation: conversation if ChatwootApp.enterprise?
