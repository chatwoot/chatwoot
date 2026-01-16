json.array! @reporting_events do |reporting_event|
  json.partial! 'api/v1/models/reporting_event', formats: [:json], reporting_event: reporting_event
end
