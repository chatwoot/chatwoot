json.id recurring_scheduled_message.id
json.content recurring_scheduled_message.content
json.inbox_id recurring_scheduled_message.inbox_id
json.conversation_id recurring_scheduled_message.conversation.display_id
json.account_id recurring_scheduled_message.account_id
json.status recurring_scheduled_message.status
json.template_params recurring_scheduled_message.template_params
json.recurrence_rule recurring_scheduled_message.recurrence_rule
json.recurrence_description recurring_scheduled_message.recurrence_description
json.occurrences_sent recurring_scheduled_message.occurrences_sent
json.author_id recurring_scheduled_message.author_id
json.author_type recurring_scheduled_message.author_type
json.created_at recurring_scheduled_message.created_at.to_i
json.updated_at recurring_scheduled_message.updated_at.to_i

if recurring_scheduled_message.author.is_a?(User)
  json.author do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: recurring_scheduled_message.author
  end
end

json.attachment recurring_scheduled_message.attachment_data if recurring_scheduled_message.attachment.attached?

pending_sm = recurring_scheduled_message.scheduled_messages.select { |sm| sm.status == 'pending' }.min_by(&:scheduled_at)
if pending_sm
  json.pending_scheduled_message do
    json.id pending_sm.id
    json.scheduled_at pending_sm.scheduled_at&.to_i
  end
end

json.scheduled_messages recurring_scheduled_message.scheduled_messages.sort_by { |sm| sm.scheduled_at || Time.zone.at(0) }.last(50).reverse do |sm|
  json.id sm.id
  json.status sm.status
  json.scheduled_at sm.scheduled_at&.to_i
  json.message_id sm.message_id
end
