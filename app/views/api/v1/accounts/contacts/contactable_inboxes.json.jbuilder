json.payload do
  json.array! @contactable_inboxes do |contactable_inbox|
    json.inbox do
      json.partial! 'api/v1/models/inbox', formats: [:json], resource: contactable_inbox[:inbox]
    end
    json.source_id contactable_inbox[:source_id]
  end
end
