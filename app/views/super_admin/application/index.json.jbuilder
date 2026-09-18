json.resources resources do |resource|
  json.id resource.id
  json.dashboard_display_name @dashboard.display_resource(resource)
end
