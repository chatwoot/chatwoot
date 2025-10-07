json.partial! 'api/v1/models/campaign', formats: [:json], resource: @campaign

json.campaign_contacts do
  json.array! @campaign_contacts do |campaign_contact|
    json.id campaign_contact.id
    json.status campaign_contact.status
    json.error_message campaign_contact.error_message
    json.sent_at campaign_contact.sent_at
    json.contact do
      json.id campaign_contact.contact.id
      json.name campaign_contact.contact.name
      json.email campaign_contact.contact.email
      json.phone_number campaign_contact.contact.phone_number
      json.thumbnail campaign_contact.contact.avatar_url
    end
  end
end

json.statistics do
  json.total @campaign_contacts.count
  json.sent @campaign_contacts.sent.count
  json.failed @campaign_contacts.failed.count
  json.pending @campaign_contacts.pending.count
  json.skipped @campaign_contacts.skipped.count
end
