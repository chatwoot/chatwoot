class MessageTemplates::Template::ChatbotReply
    pattr_initialize [:conversation!]
  
    def perform(bot_message)
      ActiveRecord::Base.transaction do
        conversation.messages.create!(chatbot_message_in_chatbox(bot_message))
      end
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
      true
    end

    def connect_with_team()
      ActiveRecord::Base.transaction do
        conversation.messages.create!(connect_with_team_message_params)
      end
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
      true
    end
  
    private
  
    delegate :contact, :account, to: :conversation
    delegate :inbox, to: :message
  
    def chatbot_message_in_chatbox(bot_message)
      content = bot_message
      {
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        message_type: :template,
        content: content
      }
    end

    def connect_with_team_message_params
      {
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        message_type: :template,
        content_type: :input_connect_with_team,
        content: I18n.t('conversations.templates.connect_with_team_message_body')
      }
    end
  end
  