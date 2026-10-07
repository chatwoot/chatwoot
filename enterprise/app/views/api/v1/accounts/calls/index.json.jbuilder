json.meta do
  json.count @calls_count
  json.current_page @calls.current_page
  json.total_pages @calls.total_pages
end

json.payload do
  json.array! @calls do |call|
    json.partial! 'api/v1/models/call', formats: [:json], call: call
  end
end
