module Captain
  module Tools
    class HandoffTool < BasePublicTool
      description 'Transfer the conversation to a human support agent'
      param :reason, type: 'string', desc: 'Optional explanation for why the handoff is occurring', required: false

      def perform(context, reason: nil)
        conversation = find_conversation(context.state)
        return 'Error: Conversation context missing' unless conversation

        reason_text = reason || 'User requested human assistance'

        log_tool_usage('handoff_triggered', {
                         conversation_id: conversation.id,
                         reason: reason_text
                       })

        execute_handoff(conversation, reason_text)

        "Conversation transferred to support team. Reason: #{reason_text}"
      rescue StandardError => e
        ChatwootExceptionTracker.new(e).capture_exception
        'Handoff failed due to an internal error'
      end

      private

      def execute_handoff(conversation, reason)
        create_private_note(conversation, reason)
        conversation.bot_handoff!
      end

      def create_private_note(conversation, content)
        conversation.messages.create!(
          message_type: :outgoing,
          private: true,
          sender: @assistant,
          account: conversation.account,
          inbox: conversation.inbox,
          content: content
        )
      end
    end
  end
end
