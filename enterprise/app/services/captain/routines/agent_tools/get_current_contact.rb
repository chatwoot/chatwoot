class Captain::Routines::AgentTools::GetCurrentContact < Captain::Routines::AgentTools::Base
  description 'Get the contact on the current conversation, including profile information, labels, attributes, and notes'

  def name = 'get_current_contact'

  def perform(tool_context)
    contact = current_conversation(tool_context).contact
    return { status: 'not_found', reason: 'The current conversation has no contact' }.to_json unless contact

    perform_operation(tool_context, 'contacts.find', contact_id: contact.id)
  end
end
