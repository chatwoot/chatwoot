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
          type: 'number',
          description: 'The ID of the contact to retrieve'
        }
      },
      required: %w[contact_id]
    }
  end

  def execute(arguments)
    contact_id = arguments['contact_id']

    Rails.logger.info "#{self.class.name}: Contact ID: #{contact_id}"

    return 'Missing required parameters' if contact_id.blank?

    contact = Contact.find_by(id: contact_id, account_id: @assistant.account_id)
    return 'Contact not found' if contact.nil?

    contact.to_llm_text
  end

  def active?
    user_has_permission('contact_manage')
  end
end
