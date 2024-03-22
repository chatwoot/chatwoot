class MessageTemplates::Template::EmailCollect
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(ways_to_reach_you_message_params)
      conversation.messages.create!(email_input_box_template_message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  def chatbot(client_message)
    ActiveRecord::Base.transaction do
      conversation.messages.create!(bot_message_in_chatbox(client_message))
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def bot_message_in_chatbox(client_message)
    content = I18n.t('prompt', client_message: client_message, account_name: account.name)
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: content
    }
  end

  def ways_to_reach_you_message_params
    content = I18n.t('conversations.templates.bot_entered_chat',
                     account_name: account.name)

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: content
    }
  end

  def email_input_box_template_message_params
    content = I18n.t('conversations.templates.email_input_box_message_body',
                     account_name: account.name)

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_email,
      content: content
    }
  end
end
