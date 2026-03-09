class WhatsappTypingJob < ApplicationJob
  queue_as :low

  def perform(conversation_id, _user_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    inbox = conversation.inbox
    whatsapp_channel = inbox.channel

    # Find last incoming message to mark as read + typing
    last_incoming = conversation.messages
                                .where(message_type: :incoming)
                                .where.not(source_id: nil)
                                .order(created_at: :desc)
                                .first

    return unless last_incoming

    Whatsapp::Providers::WhatsappCloudService
      .new(whatsapp_channel: whatsapp_channel)
      .mark_read_with_typing(last_incoming.source_id)
  end
end
