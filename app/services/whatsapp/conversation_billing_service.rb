# Records a billable WhatsApp conversation-window usage event for an account.
#
# Mirrors WhatsApp's 24-hour conversation window: the first outgoing message
# bills a credit and opens a window; further outgoing messages are free while
# either a customer reply or a previously billed message keeps that window
# open. Once 24 hours pass without either, the next outgoing message bills
# again and reopens the window.
class Whatsapp::ConversationBillingService
  pattr_initialize [:message!]

  def perform
    return unless billable_message_type?
    return if already_billed?
    return if within_free_window?

    WhatsappConversationUsage.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message: message,
      created_at: message.created_at
    )
  end

  private

  def conversation
    @conversation ||= message.conversation
  end

  def billable_message_type?
    message.outgoing? || message.template?
  end

  def already_billed?
    WhatsappConversationUsage.exists?(message_id: message.id)
  end

  def within_free_window?
    reference_time = [last_incoming_message_at, last_billed_at].compact.max
    reference_time.present? && Time.current < reference_time + 24.hours
  end

  def last_incoming_message_at
    conversation.messages.incoming.maximum(:created_at)
  end

  def last_billed_at
    WhatsappConversationUsage.where(conversation_id: conversation.id).maximum(:created_at)
  end
end
