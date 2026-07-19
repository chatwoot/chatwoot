json.payload do
  json.array! @recipients do |recipient|
    json.id recipient.id
    json.status recipient.status
    json.phone_number recipient.phone_number
    json.source_id recipient.source_id
    json.error_message recipient.error_message
    json.sent_at recipient.sent_at
    json.delivered_at recipient.delivered_at
    json.read_at recipient.read_at
    json.failed_at recipient.failed_at
    json.contact do
      if recipient.contact
        json.id recipient.contact.id
        json.name recipient.contact.name
        json.phone_number recipient.contact.phone_number
        json.email recipient.contact.email
      end
    end
  end
end
json.meta do
  json.count @recipients.total_count
  json.current_page @recipients.current_page
  json.total_pages @recipients.total_pages
end
