contact_points = resource.contact_point_data

json.id resource.id
json.name resource.name
json.email resource.email
json.additional_emails contact_points[:additional_emails]
json.email_addresses contact_points[:email_addresses]
json.phone_number resource.phone_number
json.additional_phones contact_points[:additional_phones]
json.phone_numbers contact_points[:phone_numbers]
