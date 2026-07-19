json.payload do
  json.partial! 'api/v1/models/contact', formats: [:json], resource: @contact, with_contact_inboxes: @include_contact_inboxes
  if @contact_conversation_metrics.present?
    json.conversations_count @contact_conversation_metrics[:conversations_count]
    json.open_conversations_count @contact_conversation_metrics[:open_conversations_count]
    json.resolved_conversations_count @contact_conversation_metrics[:resolved_conversations_count]
  end
end
