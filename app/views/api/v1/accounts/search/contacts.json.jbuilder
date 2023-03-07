json.payload do
  json.contacts do
    json.array! @result[:contacts] do |contact|
      json.partial! 'contact', formats: [:json], contact: contact
    end
  end
end
