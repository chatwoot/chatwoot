class MessageTemplates::Template::PhoneCollect
  pattr_initialize [:conversation!]

  def perform
    ActiveRecord::Base.transaction do
      conversation.messages.create!(ways_to_reach_you_message_params)
      conversation.messages.create!(phone_input_box_template_message_params)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  private

  delegate :contact, :account, to: :conversation
  delegate :inbox, to: :message

  def ways_to_reach_you_message_params
    content = I18n.t('conversations.templates.ways_to_reach_you_message_body',
                     account_name: account.name)

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content: content
    }
  end

  def phone_input_box_template_message_params
    content = 'Get notified by phone'

    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :template,
      content_type: :input_phone,
      content: content
    }
  end
end
