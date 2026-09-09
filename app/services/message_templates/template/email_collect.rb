class MessageTemplates::Template::EmailCollect
  pattr_initialize [:conversation!]

  def perform
    # Lock the conversation and re-check inside the lock so concurrent hook executions for the same
    # conversation can't both pass the email_collect_was_sent? guard and create a duplicate pair.
    # reload first: the conversation handed in by the message hook can carry an unpersisted display_id
    # change, and Rails refuses to row-lock a record with unsaved changes.
    conversation.reload.with_lock do
      unless conversation.messages.exists?(content_type: 'input_email')
        conversation.messages.create!(ways_to_reach_you_message_params)
        conversation.messages.create!(email_input_box_template_message_params)
      end
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
