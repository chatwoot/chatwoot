json.id resource.id
json.payment_id resource.payment_id
json.payment_url resource.payment_url
json.track_id resource.track_id
json.amount resource.amount
json.currency resource.currency
json.status resource.status
json.paid_at resource.paid_at
json.expires_at resource.expires_at
json.customer_data resource.customer_data
json.created_at resource.created_at
json.updated_at resource.updated_at

json.contact do
  if resource.contact.present?
    json.id resource.contact.id
    json.name resource.contact.name
    json.email resource.contact.email
    json.phone_number resource.contact.phone_number
  end
end

json.created_by do
  if resource.created_by.present?
    json.id resource.created_by.id
    json.name resource.created_by.name
    json.email resource.created_by.email
  end
end

json.conversation do
  if resource.conversation.present?
    json.id resource.conversation.id
    json.display_id resource.conversation.display_id
  end
end
