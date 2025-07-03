class Captain::Tools::GetContactTool < Captain::Tools::BaseAgentTool
  description 'Get details of a contact including their profile information'
  param :contact_id, type: 'number', desc: 'The ID of the contact to retrieve'

  def perform(_tool_context, contact_id:)
    log_tool_usage('get_contact', { contact_id: contact_id })

    return 'Missing required parameters' if contact_id.blank?

    contact = account_scoped(Contact).find_by(id: contact_id)
    return 'Contact not found' if contact.nil?

    contact.to_llm_text
  end

  protected

  def required_permission
    'contact_manage'
  end
end