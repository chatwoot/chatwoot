json.meta do
  json.total_count @contacts_count
  json.page @current_page
end

json.payload do
  json.array! @contacts do |contact|
    json.partial! 'api/v1/accounts/companies/contacts/contact', formats: [:json], contact: contact
  end
end
