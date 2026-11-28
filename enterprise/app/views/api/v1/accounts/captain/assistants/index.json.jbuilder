json.payload do
  json.array! @assistants do |assistant|
    json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: assistant
    json.approved_responses_count @approved_response_counts.fetch(assistant.id, 0)
    json.inbox_ids assistant.captain_inboxes.map(&:inbox_id)
  end
end

json.meta do
  json.total_count @assistants.count
  json.page 1 # Pagination not yet support at the moment, structure is reserved for future use
end
