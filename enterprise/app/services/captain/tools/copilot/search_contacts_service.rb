class Captain::Tools::Copilot::SearchContactsService < Captain::Tools::BaseService
  def name
    'search_contacts'
  end

  def description
    'Search contacts based on query parameters'
  end

  def parameters
    {
      type: 'object',
      properties: properties,
      required: []
    }
  end

  def execute(arguments)
    email = arguments['email']
    phone_number = arguments['phone_number']
    name = arguments['name']

    Rails.logger.info "#{self.class.name} Email: #{email}, Phone Number: #{phone_number}, Name: #{name}"

    contacts = Contact.where(account_id: @assistant.account_id)
    contacts = contacts.where(email: email) if email.present?
    contacts = contacts.where(phone_number: phone_number) if phone_number.present?
    contacts = contacts.where('LOWER(name) ILIKE ?', "%#{name.downcase}%") if name.present?

    return 'No contacts found' unless contacts.exists?

    contacts = contacts.limit(100)

    <<~RESPONSE
      #{contacts.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('contact_manage')
  end

  private

  def properties
    {
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
    }
  end
end
