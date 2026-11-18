# Posts the messages Captain adds when it acts on an inactive pending conversation.
class Captain::Conversation::InactivityMessageService
  FOLLOW_UP_ATTRIBUTE = 'captain_follow_up'.freeze

  pattr_initialize [:conversation!, :assistant!]

  def private_note(content)
    create_message(content: content, private: true)
  end

  def follow_up
    I18n.with_locale(conversation.account.locale) do
      create_message(
        content: I18n.t('conversations.activity.captain_follow_up_message'),
        content_attributes: { FOLLOW_UP_ATTRIBUTE => true, Enterprise::Concerns::Message::TRANSLATE_FOR_CONTACT_ATTRIBUTE => true }
      )
    end
  end

  # True when Captain's follow-up is still the latest message the customer can see.
  def follow_up_unanswered?
    conversation.messages.chat.last&.content_attributes&.dig(FOLLOW_UP_ATTRIBUTE) == true
  end

  def resolution
    Captain::Conversation::ResolutionMessageService.new(conversation: conversation, assistant: assistant).perform(use_default_message: true)
  end

  def handoff
    handoff_message = assistant.config['handoff_message']
    return if handoff_message.blank?

    create_message(content: handoff_message, preserve_waiting_since: true)
  end

  private

  def create_message(**attributes)
    conversation.messages.create!(
      message_type: :outgoing,
      sender: assistant,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      **attributes
    )
  end
end
