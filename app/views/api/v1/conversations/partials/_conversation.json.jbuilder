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

if conversation.respond_to?(:preloaded_last_message)
  message_data = conversation.preloaded_last_message.try(:push_event_data)
  json.messages message_data ? [message_data] : []
elsif conversation.messages.where(account_id: conversation.account_id).last.blank?
  json.messages []
else
  # Add limits to prevent timeout in the fallback case
  message = conversation.messages.where(account_id: conversation.account_id)
                      .order(created_at: :desc)
                      .limit(1)
                      .includes([{ attachments: [{ file_attachment: [:blob] }] }])
                      .first
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
unread_count = 0
if conversation.respond_to?(:preloaded_unread_count)
  unread_count = conversation.preloaded_unread_count
else
  unread_count = conversation.unread_incoming_messages.count
end
json.unread_count unread_count

# Handle last non-activity message for conversation - with nil safety
message_data = nil
if conversation.respond_to?(:preloaded_last_non_activity_message)
  # Preloaded data is available, even if the message itself is nil
  message_data = conversation.preloaded_last_non_activity_message.try(:push_event_data)
else
  # Optimize this query to prevent timeouts
  non_activity_message = conversation.messages
                                    .where(account_id: conversation.account_id)
                                    .where.not(message_type: Message.message_types[:activity])
                                    .order(created_at: :desc)
                                    .limit(1)
                                    .first
  message_data = non_activity_message.try(:push_event_data) if non_activity_message
end
json.last_non_activity_message message_data

json.last_activity_at conversation.last_activity_at.to_i
json.priority conversation.priority
json.waiting_since conversation.waiting_since.to_i.to_i
json.sla_policy_id conversation.sla_policy_id
json.partial! 'enterprise/api/v1/conversations/partials/conversation', conversation: conversation if ChatwootApp.enterprise?
