json.meta do
  json.count @templates_count
  json.page @current_page
end

json.payload do
  json.array! @templates do |template|
    json.partial! 'api/v1/models/csat_template', formats: [:json], resource: template
  end
end
