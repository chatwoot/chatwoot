class AppStore::SendOnAppStoreService < Base::SendOnChannelService
  private

  def channel_class
    Channel::AppStore
  end

  def perform_reply
    validate_message_support!
    source_id = channel.reply_to_review(review_id, reply_content, response_id: existing_response_id)
    message.update!(source_id: source_id) if source_id.present?
    Messages::StatusUpdateService.new(message, 'delivered').perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def validate_message_support!
    raise 'Sending attachments is not supported for App Store reviews.' if message.attachments.any?
  end

  def review_id
    message.conversation.contact_inbox.source_id
  end

  def reply_content
    message.outgoing_content.presence || message.content
  end

  def existing_response_id
    message.conversation.messages
           .outgoing
           .where.not(id: message.id)
           .where.not(source_id: [nil, ''])
           .order(created_at: :desc)
           .pick(:source_id)
  end
end
