# TODO: Move this into models jbuilder
# Currently the file there is used only for search endpoint.
# Everywhere else we use conversation builder in partials folder

json.meta do
  if conversation.contact
    json.sender do
      json.partial! 'api/v1/models/contact', formats: [:json], resource: conversation.contact
    end
  else
    json.sender({})
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assigned_entity.is_a?(AgentBot)
    json.assignee do
      json.partial! 'api/v1/models/agent_bot_slim', formats: [:json], resource: conversation.assigned_entity
    end
    json.assignee_type 'AgentBot'
  elsif conversation.assigned_entity.is_a?(User)
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
# Two distinct queries on purpose: the seed below is the pagination cursor and
# must be the newest renderable message, while `last_non_activity_message` is
# the chat list preview and must skip activity messages. See the invariants
# documented on both `Conversation` methods before touching either.
seed_message = conversation.dashboard_seed_message
json.messages seed_message ? [seed_message.push_event_data] : []

json.account_id conversation.account_id
json.uuid conversation.uuid
json.additional_attributes conversation.additional_attributes
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.assignee_last_seen_at conversation.assignee_last_seen_at.to_i
json.can_reply conversation.can_reply?
json.anonymous_caller conversation.contact_inbox.anonymous_caller?
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.custom_attributes conversation.custom_attributes
json.inbox_id conversation.inbox_id
json.labels conversation.cached_label_list_array
json.muted conversation.muted?
json.snoozed_until conversation.snoozed_until
json.status conversation.status
json.created_at conversation.created_at.to_i
json.updated_at conversation.updated_at&.floor(6).to_f
json.timestamp conversation.last_activity_at.to_i
json.first_reply_created_at conversation.first_reply_created_at.to_i
json.unread_count conversation.unread_incoming_messages.count
last_non_activity_message = conversation.last_non_activity_message
if last_non_activity_message
  json.last_non_activity_message do
    json.merge! last_non_activity_message.push_event_data
    if last_non_activity_message.reaction?
      target_id = last_non_activity_message.content_attributes['in_reply_to']
      target = target_id.present? ? conversation.messages.find_by(id: target_id) : nil
      # strip_tags so the preview of an HTML/email target doesn't render as
      # literal "<p>..." markup in the chat list card. Wrap with `String.new`
      # because `strip_tags` returns `ActiveSupport::SafeBuffer`, which
      # Sidekiq's strict-args check rejects when this hash flows into a cable
      # broadcast job (event_data_presenter.rb shares the same pattern).
      if target&.content.present?
        plain_snippet = String.new(ActionController::Base.helpers.strip_tags(target.content))
        json.in_reply_to_snippet plain_snippet.truncate(60)
      end
    end
  end
else
  json.last_non_activity_message nil
end
json.last_activity_at conversation.last_activity_at.to_i
json.group_type conversation.group_type
# Whether THIS thread's number has left the WhatsApp group. The group contact is
# account-scoped and can be in two inboxes of one account, so the answer belongs to the
# conversation rather than to the contact every thread shares. Only groups carry it:
# `contact_inbox` is preloaded for the list, but the question is meaningless anywhere
# else and an always-false field on every conversation is noise.
json.group_left conversation.contact_inbox&.group_left? if conversation.group_type_group?
# When this number's session last answered that it has no WhatsApp account, which is what the
# conversation warns about. Only WhatsApp inboxes carry it; nil once the number is known to exist.
json.whatsapp_missing_checked_at conversation.contact_inbox&.whatsapp_missing_checked_at&.to_i if conversation.inbox.whatsapp?
json.priority conversation.priority
json.waiting_since conversation.waiting_since.to_i.to_i
sla_applicable = conversation.account.feature_enabled?('sla') && (!conversation.respond_to?(:sla_applicable?) || conversation.sla_applicable?)
json.sla_policy_id sla_applicable ? conversation.sla_policy_id : nil
json.partial! 'enterprise/api/v1/conversations/partials/conversation', conversation: conversation if ChatwootApp.enterprise?
