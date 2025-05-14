class AutoResolveIdleConversationsJob < ApplicationJob
  queue_as :default

  def perform
    cutoff_time = 5.minutes.ago

    conversations = Conversation.where(status: 0)
                                .where('conversations.updated_at < ?', cutoff_time)
                                .joins(:messages)
                                .group('conversations.id')
                                .having('MAX(messages.sender_type) = ?', 'Contact')

    conversations.find_each do |conversation|
      Message.create!(
        content: 'Apakah Anda masih bersama kami? Jika masih memerlukan bantuan, silakan balas pesan ini. Kami siap membantu Anda.',
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        conversation_id: conversation.id,
        message_type: 1,
        content_type: 0,
        sender_type: 'User',
        sender_id: conversation.assignee_id,
        status: 0
      )

      conversation.update!(status: 1, assignee_id: nil)
    rescue StandardError => e
      Rails.logger.error("[AutoResolveIdleConversationsJob] Failed to resolve conversation ##{conversation.id}: #{e.message}")
      next
    end
  end
end
