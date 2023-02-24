json.payload do
  json.contacts do
    json.array! @result[:contacts] do |contact|
      json.partial! 'api/v1/models/multi_search_contact', formats: [:json], contact: contact
    end
  end
end
