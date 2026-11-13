json.payload do
  json.array! @copilot_threads do |thread|
    json.partial! 'api/v1/models/captain/copilot_thread', resource: thread
  end
end
json.meta do
  json.total_count @copilot_threads.total_count
  json.page @copilot_threads.current_page
end
