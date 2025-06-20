json.id @contact.id
json.shopify_customer_id @contact.custom_attributes['shopify_customer_id']
json.has_email @contact.email.present?
json.has_name @contact.name.present?
json.has_phone_number @contact.phone_number.present?
json.identifier @contact.identifier
