json.payload do
  json.array! @responses do |response|
    json.partial! 'api/v1/models/captain/assistant_response', formats: [:json], resource: response
    json.used_in_conversations_count @response_usage_counts.fetch(response.id, 0) if response.documentable_type == 'User' && @response_usage_counts
  end
end

json.meta do
  json.total_count @responses_count
  json.page @current_page
end
