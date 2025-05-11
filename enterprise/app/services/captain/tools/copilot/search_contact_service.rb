class Captain::Tools::Copilot::SearchContactService < Captain::Tools::BaseService
  def name
    'search_contact'
  end

  def description
    'Search for contacts based on query parameters'
  end

  def parameters
    {
      type: 'object',
      properties: {
        account_id: {
          type: 'number',
          description: 'The ID of the account to search contacts in'
        },
        email: {
          type: 'string',
          description: 'Filter contacts by email'
        },
        phone_number: {
          type: 'string',
          description: 'Filter contacts by phone number'
        },
        name: {
          type: 'string',
          description: 'Filter contacts by name (partial match)'
        }
      },
      required: %w[account_id]
    }
  end

  def execute(arguments)
    account_id = arguments['account_id']
    email = arguments['email']
    phone_number = arguments['phone_number']
    name = arguments['name']

    Rails.logger.info do
      "[CAPTAIN][SearchContact] account_id: #{account_id}, email: #{email}, phone_number: #{phone_number}, name: #{name}"
    end

    return 'Missing required parameters' if account_id.blank?

    contacts = Contact.where(account_id: account_id)
    contacts = contacts.where(email: email) if email.present?
    contacts = contacts.where(phone_number: phone_number) if phone_number.present?
    contacts = contacts.where('name ILIKE ?', "%#{name}%") if name.present?

    return 'No contacts found' unless contacts.exists?

    <<~RESPONSE
      Total number of contacts: #{contacts.count}
      #{
        contacts.map do |contact|
          contact.to_llm_text
        end.join("\n---\n")
      }
    RESPONSE
  end
end
