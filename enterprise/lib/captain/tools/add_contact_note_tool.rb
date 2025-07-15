class Captain::Tools::AddContactNoteTool < Captain::Tools::BaseAgentTool
  description 'Add a note to a contact profile'
  param :contact_id, type: 'string', desc: 'The ID of the contact'
  param :note, type: 'string', desc: 'The note content to add to the contact'

  def perform(_tool_context, note:, contact_id:)
    log_tool_usage('add_contact_note', { contact_id: contact_id, note_length: note.length })

    return 'Missing required parameters: contact_id, note' if note.blank? || contact_id.blank?

    contact = find_contact(contact_id)
    return 'Contact not found' unless contact

    create_contact_note(contact, note)
    "Note added successfully to contact #{contact.name} (ID: #{contact.id})"
  end

  private

  def find_contact(contact_id)
    account_scoped(::Contact).find_by(id: contact_id)
  end

  def create_contact_note(contact, note)
    contact.notes.create!(
      account: @assistant.account,
      contact: contact,
      content: note,
      user: @user
    )
  end

  def active?
    user_has_permission('contact_manage')
  end
end
