# TODO: Move this into models jbuilder
# Currently the file there is used only for search endpoint.
# Everywhere else we use conversation builder in partials folder

json.meta do
  json.sender do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: conversation.contact
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assigned_entity.is_a?(AgentBot)
    json.assignee do
      json.partial! 'api/v1/models/agent_bot_slim', formats: [:json], resource: conversation.assigned_entity
    end
    json.assignee_type 'AgentBot'
  elsif conversation.assignee_type == 'User'
    json.assignee do
      json.partial! 'api/v1/models/agent', formats: [:json], resource: conversation.assigned_entity
    end
    json.assignee_type 'User'
  end
  json.partial! 'enterprise/api/v1/conversations/partials/assignee', conversation: conversation if ChatwootApp.enterprise?
  if conversation.team.present?
    json.team do
      json.partial! 'api/v1/models/team', formats: [:json], resource: conversation.team
    end
  end
  json.hmac_verified conversation.contact_inbox&.hmac_verified
end

json.id conversation.display_id
# The dashboard seeds the message thread from this array and then paginates BACKWARD
# by id (before: messages[0].id). Keep the seed as the chronologically latest message,
# but add an id tiebreaker: without it, same-second siblings (e.g. the input_csat survey
# created alongside activity messages during an auto-resolve burst) could resolve to a
# lower-id activity, and backward pagination would then never load the higher-id survey.
last_message = conversation.messages.where(account_id: conversation.account_id)
                           .includes([{ attachments: [{ file_attachment: [:blob] }] }])
                           .reorder(created_at: :desc, id: :desc).first
if last_message.blank?
  json.messages []
else
  json.messages [last_message.try(:push_event_data)]
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
json.unread_count conversation.unread_incoming_messages.count
json.last_non_activity_message conversation.messages.where(account_id: conversation.account_id).non_activity_messages.first.try(:push_event_data)
json.last_activity_at conversation.last_activity_at.to_i
json.priority conversation.priority
json.waiting_since conversation.waiting_since.to_i.to_i
sla_applicable = conversation.account.feature_enabled?('sla') && (!conversation.respond_to?(:sla_applicable?) || conversation.sla_applicable?)
json.sla_policy_id sla_applicable ? conversation.sla_policy_id : nil
json.partial! 'enterprise/api/v1/conversations/partials/conversation', conversation: conversation if ChatwootApp.enterprise?
