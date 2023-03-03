json.payload do
  json.messages do
    json.array! @result[:messages] do |message|
      json.partial! 'message', formats: [:json], message: message
    end
  end
end
