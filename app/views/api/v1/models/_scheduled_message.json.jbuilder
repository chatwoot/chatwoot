json.id scheduled_message.id
json.content scheduled_message.content
json.inbox_id scheduled_message.inbox_id
json.conversation_id scheduled_message.conversation.display_id
json.account_id scheduled_message.account_id
json.status scheduled_message.status
json.scheduled_at scheduled_message.scheduled_at&.to_i
json.template_params scheduled_message.template_params
json.author_id scheduled_message.author_id
json.author_type scheduled_message.author_type
json.message_id scheduled_message.message_id
json.created_at scheduled_message.created_at.to_i
json.updated_at scheduled_message.updated_at.to_i

if scheduled_message.author.is_a?(User)
  json.author do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: scheduled_message.author
  end
elsif scheduled_message.author.present?
  json.author do
    json.id scheduled_message.author_id
    json.type scheduled_message.author_type
    json.name scheduled_message.author.respond_to?(:name) ? scheduled_message.author.name : nil
  end
end

json.attachment scheduled_message.attachment_data if scheduled_message.attachment.attached?

if scheduled_message.recurring_scheduled_message_id.present?
  json.recurring_scheduled_message_id scheduled_message.recurring_scheduled_message_id
  json.recurrence_rule scheduled_message.recurring_scheduled_message&.recurrence_rule
end
