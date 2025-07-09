class Captain::Tools::AddContactNoteTool < Captain::Tools::BaseAgentTool
  description 'Add a note to a contact profile'
  param :contact_id, type: 'string', desc: 'The ID of the contact (optional if conversation_id is provided)'
  param :conversation_id, type: 'string', desc: 'The display ID of the conversation to find the contact (optional if contact_id is provided)'
  param :note, type: 'string', desc: 'The note content to add to the contact'

  def perform(_tool_context, note:, contact_id: nil, conversation_id: nil)
    log_tool_usage('add_contact_note', { contact_id: contact_id, conversation_id: conversation_id, note_length: note.length })

    return 'Missing required parameters: need either contact_id or conversation_id, and note' if note.blank?
    return 'Must provide either contact_id or conversation_id' if contact_id.blank? && conversation_id.blank?

    contact = nil

    if contact_id.present?
      contact = account_scoped(::Contact).find_by(id: contact_id)
      return 'Contact not found' if contact.nil?
    elsif conversation_id.present?
      conversation = account_scoped(::Conversation).find_by(display_id: conversation_id)
      return 'Conversation not found' if conversation.nil?

      contact = conversation.contact
    end

    # Create contact note
    contact.notes.create!(
      account: @assistant.account,
      contact: contact,
      content: note,
      user: @user
    )

    "Note added successfully to contact #{contact.name} (ID: #{contact.id})"
  end

  def active?
    user_has_permission('contact_manage')
  end
end