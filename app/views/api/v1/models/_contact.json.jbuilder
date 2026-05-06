contact_points = resource.contact_point_data

json.additional_attributes resource.additional_attributes
json.availability_status resource.availability_status
json.email resource.email
json.additional_emails contact_points[:additional_emails]
json.email_addresses contact_points[:email_addresses]
json.id resource.id
json.name resource.name
json.phone_number resource.phone_number
json.additional_phones contact_points[:additional_phones]
json.phone_numbers contact_points[:phone_numbers]
json.blocked resource.blocked
json.identifier resource.identifier
json.thumbnail resource.avatar_url
json.custom_attributes resource.custom_attributes
json.last_activity_at resource.last_activity_at.to_i if resource[:last_activity_at].present?
json.created_at resource.created_at.to_i if resource[:created_at].present?
# we only want to output contact inbox when its /contacts endpoints
if defined?(with_contact_inboxes) && with_contact_inboxes.present?
  json.contact_inboxes do
    json.array! resource.contact_inboxes do |contact_inbox|
      json.partial! 'api/v1/models/contact_inbox', formats: [:json], resource: contact_inbox
    end
  end
end
