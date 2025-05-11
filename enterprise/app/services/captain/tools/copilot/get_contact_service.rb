class Captain::Tools::Copilot::GetContactService < Captain::Tools::BaseService
  def name
    'get_contact'
  end

  def description
    'Get details of a contact including their profile information'
  end

  def parameters
    {
      type: 'object',
      properties: {
        contact_id: {
          type: 'string',
          description: 'The ID of the contact to retrieve'
        },
        account_id: {
          type: 'string',
          description: 'The ID of the account the contact belongs to'
        }
      },
      required: %w[contact_id account_id]
    }
  end

  def execute(arguments)
    contact_id = arguments['contact_id']
    account_id = arguments['account_id']

    Rails.logger.info { "[CAPTAIN][GetContact] #{contact_id}, #{account_id}" }

    return 'Missing required parameters' if contact_id.blank? || account_id.blank?

    contact = Contact.find_by(id: contact_id, account_id: account_id)
    return 'Contact not found' if contact.nil?

    contact.to_llm_text
  end
end
