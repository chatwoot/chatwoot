class Whatsapp::SendReadReceiptsJob < ApplicationJob
  queue_as :low

  def perform(conversation_id, agent_last_seen_at)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation
    return unless conversation.inbox.channel.is_a?(Channel::Whatsapp)
    return unless conversation.inbox.channel.provider == 'whapi'

    # Find all incoming messages that were created before the agent viewed the conversation
    unread_incoming_messages = conversation.messages
                                           .where(message_type: 'incoming')
                                           .where('created_at <= ?', agent_last_seen_at)
                                           .where.not(source_id: [nil, ''])

    # Send read receipts for each message
    unread_incoming_messages.find_each do |message|
      Whatsapp::SendReadReceiptService.new(message: message).perform
    end
  end
end