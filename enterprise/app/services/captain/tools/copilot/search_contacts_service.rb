class Captain::Tools::Copilot::SearchContactsService < Captain::Tools::BaseTool
  def self.name
    'search_contacts'
  end

  description 'Search contacts based on query parameters'
  param :email, type: :string, desc: 'Filter contacts by email'
  param :phone_number, type: :string, desc: 'Filter contacts by phone number'
  param :name, type: :string, desc: 'Filter contacts by name (partial match)'

  def execute(email: nil, phone_number: nil, name: nil)
    Rails.logger.info "FOUND CONTACTS: #{self.class.name}: Email: #{email}, Phone Number: #{phone_number}, Name: #{name}"

    contacts = Contact.where(account_id: @assistant.account_id)
    contacts = contacts.where(email: email) if email.present?
    contacts = contacts.where(phone_number: phone_number) if phone_number.present?
    <<~RESPONSE
      #{contacts.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('contact_manage')
  end
end
