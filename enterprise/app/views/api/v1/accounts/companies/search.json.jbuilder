json.meta do
  json.total_count @companies_count
  json.page @current_page
end

json.payload do
  json.array! @companies do |company|
    json.partial! 'api/v1/models/company', formats: [:json], resource: company
  end
end
