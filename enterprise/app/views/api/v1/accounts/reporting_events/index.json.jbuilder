json.payload do
  json.array! @reporting_events do |reporting_event|
    json.partial! 'api/v1/models/reporting_event', formats: [:json], reporting_event: reporting_event
  end
end

json.meta do
  json.count @total_count
  json.current_page @current_page
  json.total_pages @reporting_events.total_pages
end
