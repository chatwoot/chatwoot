json.id @contact.id
json.unverfied_shopify_email @contact.unverfied_shopify_email
json.verified_shopify_id @contact.verified_shopify_id
json.has_email @contact.email.present?
json.has_name @contact.name.present?
json.has_phone_number @contact.phone_number.present?
json.identifier @contact.identifier
