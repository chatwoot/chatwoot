json.meta do
  json.count @companies.total_count
  json.current_page @companies.current_page
end

json.payload do
  json.array! @companies do |company|
    json.partial! 'api/v1/accounts/companies/show', formats: [:json], company: company
  end
end
