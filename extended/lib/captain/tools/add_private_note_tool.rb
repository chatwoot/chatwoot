module Captain
  module Tools
    class AddPrivateNoteTool < BasePublicTool
      description 'Create a private internal note on the conversation'
      param :note, type: 'string', desc: 'Text content of the private note'

      def perform(context, note:)
        conversation = find_conversation(context.state)
        return 'Error: Conversation context missing' unless conversation
        return 'Error: Note content cannot be empty' if note.blank?

        log_tool_usage('private_note_created', {
                         conversation_id: conversation.id,
                         length: note.length
                       })

        save_private_note(conversation, note)

        'Private note successfully recorded'
      end

      def permissions
        %w[conversation_manage conversation_unassigned_manage conversation_participating_manage]
      end

      private

      def save_private_note(conversation, content)
        conversation.messages.create!(
          account: @assistant.account,
          inbox: conversation.inbox,
          sender: @assistant,
          message_type: :outgoing,
          content: content,
          private: true
        )
      end
    end
  end
end
