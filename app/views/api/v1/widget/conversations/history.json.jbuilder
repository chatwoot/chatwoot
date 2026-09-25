json.unread_count @unread_count
json.payload do
  json.array! @history do |item|
    json.id item.display_id
    json.cursor item.id
    json.inbox_id item.inbox_id
    json.status item.status
    json.contact_last_seen_at item.contact_last_seen_at.to_i
    json.unread_count item.messages.where(private: false, message_type: :outgoing).where('created_at > ?',
                                                                                         item.contact_last_seen_at || Time.zone.at(0)).count
    json.updated_at item.updated_at.to_i
    last_message = item.messages.where(private: false, message_type: [:incoming, :outgoing]).last
    if last_message
      json.last_message do
        json.partial! 'api/v1/models/widget_message', resource: last_message
      end
    end
  end
end
