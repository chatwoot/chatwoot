json.array! @panels do |panel|
  json.partial! 'api/v1/models/saved_report_panel', formats: [:json], resource: panel
end
