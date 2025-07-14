class Captain::Tools::SearchContactTool < Captain::Tools::BaseAgentTool
  description 'Search for a contact by email, phone number, or identifier'
  param :query, type: 'string', desc: 'Email, phone number, or identifier to search for'

  def perform(_tool_context, query:)
    log_tool_usage('search_contact', { query: query })

    query = query&.strip
    return error_response('Query is required') if query.blank?

    contact = find_contact(query)

    if contact
      success_response(format_contact(contact))
    else
      error_response('No contact found')
    end
  end

  private

  def find_contact(query)
    account_scoped(Contact)
      .where('email = :query OR phone_number = :query OR identifier = :query', query: query)
      .first
  end

  def format_contact(contact)
    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      identifier: contact.identifier,
      blocked: contact.blocked,
      contact_type: contact.contact_type,
      additional_attributes: contact.additional_attributes,
      custom_attributes: contact.custom_attributes
    }
  end

  def success_response(contact_data)
    {
      success: true,
      contact: contact_data
    }
  end

  def error_response(message)
    {
      success: false,
      error: message
    }
  end
end