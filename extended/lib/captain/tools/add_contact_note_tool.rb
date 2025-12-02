module Captain
  module Tools
    class AddContactNoteTool < BasePublicTool
      description 'Append a new note to the contact profile'
      param :note, type: 'string', desc: 'Content of the note to be added'

      def perform(context, note:)
        contact = find_contact(context.state)
        return 'Error: Contact context missing' unless contact
        return 'Error: Note content cannot be empty' if note.blank?

        log_tool_usage('contact_note_creation', {
                         contact_id: contact.id,
                         length: note.length
                       })

        persist_note(contact, note)

        "Successfully added note to contact: #{contact.name}"
      end

      def permissions
        %w[contact_manage]
      end

      private

      def persist_note(contact, content)
        contact.notes.create!(content: content)
      end
    end
  end
end
