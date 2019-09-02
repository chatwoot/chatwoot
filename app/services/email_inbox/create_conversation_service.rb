module EmailInbox
  class CreateConversationService
    pattr_initialize :account, :employee

    def perform
      ActiveRecord::Base.transaction do
        build_conversation
        build_message
      end
    end

    private

    def inbox
      @inbox ||= Inbox.find(options[:inbox_id])
    end

    def contact
      @contact ||= Contact.find(options[:contact_id])
    end

    def build_conversation
      @conversation ||=
      if (conversation = Conversation.find_by(conversation_params))
        conversation
      else
        Conversation.create!(conversation_params)
      end
    end

    def build_message
      @message = @conversation.messages.new(message_params)
      @message.save!
    end

    def conversation_params
      {
        account_id: inbox.account_id,
        inbox_id: inbox.id,
        sender_id: options[:contact_id]
      }
    end

    def message_params
      {
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        message_type: 0,
        content: options[:content],
      }
    end
  end
end
