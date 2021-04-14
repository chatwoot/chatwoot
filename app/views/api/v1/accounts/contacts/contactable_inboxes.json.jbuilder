json.payload do
  json.array! @contactable_inboxes do |contactable_inbox|
    json.inbox contactable_inbox[:inbox]
    json.source_id contactable_inbox[:source_id]
  end
end
