json.data @paginated_messages do |campaign_message|
  json.contact do
    json.id campaign_message.contact.id
    json.name campaign_message.contact.name
    json.phone_number campaign_message.contact.phone_number
  end
  json.status campaign_message.status
  json.error_code campaign_message.error_code
  json.error_description campaign_message.error_description
  json.sent_at campaign_message.sent_at
  json.delivered_at campaign_message.delivered_at
  json.read_at campaign_message.read_at
  json.created_at campaign_message.created_at
end

json.meta do
  json.total @paginated_messages.total_count
  json.page @paginated_messages.current_page
  json.per_page @paginated_messages.limit_value
  json.total_pages @paginated_messages.total_pages
end
