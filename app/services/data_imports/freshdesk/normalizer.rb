class DataImports::Freshdesk::Normalizer
  WEB_CHAT_SOURCE = 15

  def contact(contact)
    {
      'id' => contact['id']&.to_s,
      'name' => contact['name'],
      'email' => contact['email'],
      'phone' => contact['mobile'].presence || contact['phone'],
      'external_id' => contact['unique_external_id'].presence || contact['external_id'],
      'created_at' => unix_timestamp(contact['created_at']),
      'updated_at' => unix_timestamp(contact['updated_at']),
      'last_seen_at' => unix_timestamp(contact['updated_at']),
      'other_emails' => contact['other_emails'],
      'custom_fields' => contact['custom_fields'].presence || contact['custom_field'],
      'tags' => contact['tags']
    }.compact
  end

  def ticket(ticket, conversations)
    {
      'id' => ticket['id'].to_s,
      'created_at' => unix_timestamp(ticket['created_at']),
      'updated_at' => unix_timestamp(ticket['updated_at']),
      'source' => ticket_source(ticket),
      'contacts' => { 'contacts' => conversation_contacts(ticket, conversations) },
      'conversation_parts' => conversation_parts(conversations)
    }.merge(ticket_metadata(ticket)).compact
  end

  private

  def ticket_source(ticket)
    source = {
      'id' => ticket['id'].to_s,
      'type' => DataImports::Freshdesk::SourceBucket.source_type(ticket['source']),
      'subject' => ticket['subject'],
      'body' => ticket['description'].presence || ticket['description_text'],
      'attachments' => ticket['attachments'],
      'author' => source_author(ticket)
    }.compact

    source.except!('subject', 'body') if ticket['source'].to_i == WEB_CHAT_SOURCE
    source
  end

  def source_author(ticket)
    requester(ticket).merge('type' => outgoing_source?(ticket) ? 'admin' : 'contact')
  end

  def outgoing_source?(ticket)
    [10, 14].include?(ticket['source'].to_i)
  end

  def requester(ticket)
    requester = ticket['requester'].is_a?(Hash) ? ticket['requester'] : {}
    contact(requester.merge('id' => requester['id'] || ticket['requester_id']))
  end

  def conversation_parts(conversations)
    sorted_conversations = conversations.each_with_index.sort_by do |conversation, index|
      [conversation['created_at'].to_s, index]
    end.map(&:first)
    {
      'conversation_parts' => sorted_conversations.map { |conversation| message(conversation) },
      'total_count' => conversations.size
    }
  end

  def conversation_contacts(ticket, conversations)
    contacts = [requester(ticket)]
    contacts.concat(conversations.filter_map { |conversation| conversation_contact(conversation) })
    contacts.uniq { |contact_payload| contact_payload['id'].presence || contact_payload['email'].to_s.downcase.presence }
  end

  def conversation_contact(conversation)
    return unless conversation['incoming']
    return if conversation['user_id'].blank? && conversation['from_email'].blank?

    {
      'id' => conversation['user_id']&.to_s,
      'name' => conversation['from_email'],
      'email' => conversation['from_email']
    }.compact
  end

  def ticket_metadata(ticket)
    {
      'subject' => ticket['subject'],
      'status' => ticket['status'],
      'priority' => ticket['priority'],
      'requester_id' => ticket['requester_id'],
      'responder_id' => ticket['responder_id'],
      'group_id' => ticket['group_id'],
      'company_id' => ticket['company_id'],
      'tags' => ticket['tags'],
      'custom_fields' => ticket['custom_fields'],
      'archived' => ticket['archived']
    }
  end

  def message(conversation)
    message_attributes(conversation).merge(message_metadata(conversation)).compact
  end

  def message_attributes(conversation)
    {
      'id' => conversation['id'].to_s,
      'part_type' => conversation['private'] ? 'note' : 'comment',
      'body' => conversation['body'].presence || conversation['body_text'],
      'attachments' => conversation['attachments'],
      'created_at' => unix_timestamp(conversation['created_at']),
      'updated_at' => unix_timestamp(conversation['updated_at']),
      'author' => message_author(conversation)
    }
  end

  def message_metadata(conversation)
    conversation.slice(
      'source', 'incoming', 'private', 'from_email', 'to_emails', 'cc_emails', 'bcc_emails', 'deleted'
    )
  end

  def message_author(conversation)
    {
      'id' => conversation['user_id']&.to_s,
      'type' => conversation['incoming'] ? 'contact' : 'admin',
      'name' => conversation['from_email'],
      'email' => conversation['from_email']
    }.compact
  end

  def unix_timestamp(value)
    return if value.blank?

    Time.zone.parse(value.to_s).to_i
  end
end
