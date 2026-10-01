class Captain::Tools::AddContactNoteTool < Captain::Tools::BasePublicTool
  description 'Add a note to a contact profile'
  param :note, type: 'string', desc: 'The note content to add to the contact'

  def perform(tool_context, note:)
    contact = find_contact(tool_context.state)
    return failure_result('Contact not found', tool_context.state) unless contact

    return failure_result('Note content is required', tool_context.state) if note.blank?

    log_tool_usage('add_contact_note', { contact_id: contact.id, note_length: note.length })

    create_contact_note(contact, note)
    "Note added successfully to contact #{contact.name} (ID: #{contact.id})"
  end

  private

  def create_contact_note(contact, note)
    contact.notes.create!(content: note)
  end

  def permissions
    %w[contact_manage]
  end
end
