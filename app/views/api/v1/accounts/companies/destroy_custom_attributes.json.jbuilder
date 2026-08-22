json.payload do
  json.partial! 'api/v1/accounts/companies/show', formats: [:json], company: @company
end
