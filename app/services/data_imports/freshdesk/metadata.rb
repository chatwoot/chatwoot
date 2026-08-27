class DataImports::Freshdesk::Metadata
  def contact_custom_attributes(contact)
    {
      freshdesk_contact_id: contact['id'],
      freshdesk_unique_external_id: contact['external_id']
    }.compact
  end

  def contact_source(contact)
    {
      contact_id: contact['id'],
      unique_external_id: contact['external_id'],
      raw_phone: contact['phone'],
      other_emails: contact['other_emails'],
      custom_fields: contact['custom_fields'],
      tags: contact['tags']
    }.compact
  end

  def conversation_source(conversation)
    {
      ticket_id: conversation['id'],
      subject: conversation['subject'],
      status: conversation['status'],
      priority: conversation['priority'],
      requester_id: conversation['requester_id'],
      responder_id: conversation['responder_id'],
      group_id: conversation['group_id'],
      company_id: conversation['company_id'],
      tags: conversation['tags'],
      custom_fields: conversation['custom_fields'],
      archived: conversation['archived']
    }.compact
  end

  def message_source(part)
    {
      conversation_id: part['id'],
      conversation_source: part['source'],
      user_id: part.dig('author', 'id'),
      incoming: part['incoming'],
      private: part['private'],
      from_email: part['from_email'],
      to_emails: part['to_emails'],
      cc_emails: part['cc_emails'],
      bcc_emails: part['bcc_emails'],
      attachments: part['attachments'],
      deleted: part['deleted']
    }.compact
  end
end
