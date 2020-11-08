json.additional_attributes resource.additional_attributes
json.availability_status resource.availability_status
json.email resource.email
json.id resource.id
json.name resource.name
json.phone_number resource.phone_number
json.thumbnail resource.avatar_url
json.custom_attributes resource.custom_attributes
json.conversations_count resource.conversations_count if resource[:conversations_count].present?
json.last_seen_at resource.last_seen_at if resource[:last_seen_at].present?

# we only want to output contact inbox when its /contacts endpoints
if defined?(with_contact_inboxes) && with_contact_inboxes.present?
  json.contact_inboxes do
    json.array! resource.contact_inboxes do |contact_inbox|
      json.partial! 'api/v1/models/contact_inbox.json.jbuilder', resource: contact_inbox
    end
  end
end
