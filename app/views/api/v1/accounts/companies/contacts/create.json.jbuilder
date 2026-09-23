json.payload do
  json.partial! 'api/v1/accounts/companies/contacts/contact', formats: [:json], contact: @contact
end
