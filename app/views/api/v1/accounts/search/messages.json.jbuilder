json.payload do
  json.messages do
    json.array! @result[:messages] do |message|
      json.partial! 'api/v1/models/multi_search_message', formats: [:json], message: message
    end
  end
end
