json.payload do
  json.messages do
    json.array! @result[:messages] do |message|
      json.partial! 'message', formats: [:json], message: message
    end
  end
  json.meta do
    json.current_page @search_service.current_page
    json.total_count @result[:messages_count]
    json.total_pages @search_service.total_pages
  end
end
