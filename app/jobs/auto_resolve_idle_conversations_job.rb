class AutoResolveIdleConversationsJob < ApplicationJob
  queue_as :default

  def perform
    cutoff_time = 5.minutes.ago
    cutoff_time_reminded = 5.minutes.ago
    # Close Conversation
    conversations_to_resolve = Conversation.where(status: 0, is_reminded: true)
                                           .where('conversations.updated_at < ?', cutoff_time_reminded)
                                           .joins(:messages)
                                           .group('conversations.id')
    conversations_to_resolve.find_each do |conversation|
      Message.create!(
        content: 'Karena belum ada respon, sesi chat ini akan kami akhiri. Jika Anda membutuhkan bantuan di lain waktu, jangan ragu untuk menghubungi kami kembali. Terima kasih.',
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        conversation_id: conversation.id,
        message_type: 1,
        content_type: 0,
        sender_type: 'User',
        sender_id: conversation.assignee_id,
        status: 0
      )

      conversation.update!(status: 1, assignee_id: nil, is_reminded: false)
    rescue StandardError => e
      Rails.logger.error("[AutoResolveIdleConversationsJob] Failed to resolve conversation ##{conversation.id}: #{e.message}")
      next
    end
    # Remind Conversation
    conversations_to_remind = Conversation.where(status: 0, is_reminded: false)
                                          .where('conversations.updated_at < ?', cutoff_time)
                                          .joins(:messages)
                                          .group('conversations.id')
                                          .having('MAX(messages.sender_type) = ?', 'Contact')

    Rails.logger.info(conversations_to_remind.inspect)
    conversations_to_remind.find_each do |conversation|
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

      conversation.update!(is_reminded: true)
    rescue StandardError => e
      Rails.logger.error("[AutoResolveIdleConversationsJob] Failed to remind conversation ##{conversation.id}: #{e.message}")
      next
    end
  end
end
