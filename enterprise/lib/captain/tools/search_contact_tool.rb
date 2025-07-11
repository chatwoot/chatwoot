class Captain::Tools::SearchContactTool < Captain::Tools::BaseAgentTool
  def name
    'search_contact'
  end

  def display_name
    'Search Contact'
  end

  def description
    'Search for a contact by email, phone number, or identifier'
  end

  def execute(arguments = {})
    query = arguments[:query]&.strip
    return error_response('Query is required') if query.blank?

    contact = find_contact(query)

    if contact
      success_response(format_contact(contact))
    else
      error_response('No contact found')
    end
  end

  def json_schema
    {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'Email, phone number, or identifier to search for'
        }
      },
      required: ['query']
    }
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