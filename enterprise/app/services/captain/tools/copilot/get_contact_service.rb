class Captain::Tools::Copilot::GetContactService < Captain::Tools::BaseTool
  def self.name
    'get_contact'
  end
  description 'Get details of a contact including their profile information'
  param :contact_id, type: :number, desc: 'The ID of the contact to retrieve', required: true

  def execute(contact_id:)
    contact = Contact.find_by(id: contact_id, account_id: @assistant.account_id)
    return 'Contact not found' if contact.nil?

    contact.to_llm_text
  end

  def active?
    user_has_permission('contact_manage')
  end
end
