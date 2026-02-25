json.array! @dashboard_apps do |dashboard_app|
  json.partial! 'api/v1/models/dashboard_app', formats: [:json], resource: dashboard_app
end
