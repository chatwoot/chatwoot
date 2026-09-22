json.payload do
  json.array! @copilot_threads do |thread|
    json.partial! 'api/v1/models/captain/copilot_thread', resource: thread
  end
end

json.meta do
  json.page @copilot_threads.current_page
  json.total_count @copilot_threads.total_count
  json.next_page @copilot_threads.next_page
end
