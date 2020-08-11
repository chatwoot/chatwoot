json.additional_attributes resource.additional_attributes
json.availability_status resource.availability_status
json.email resource.email
json.id resource.id
json.name resource.name
json.phone_number resource.phone_number
json.thumbnail resource.avatar_url
json.contact_inboxes do
  json.array! resource.contact_inboxes do |contact_inbox|
    json.partial! 'api/v1/models/contact_inbox.json.jbuilder', resource: contact_inbox
  end
end
