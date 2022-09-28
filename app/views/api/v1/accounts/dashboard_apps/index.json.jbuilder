json.array! @dashboard_apps do |dashboard_app|
  json.partial! 'api/v1/models/dashboard_app.json.jbuilder', resource: dashboard_app
end
