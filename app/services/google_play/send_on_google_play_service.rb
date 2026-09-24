class GooglePlay::SendOnGooglePlayService < Base::SendOnChannelService
  private

  def channel_class
    Channel::GooglePlay
  end

  def perform_reply
    source_id = channel.reply_to_review(message.conversation.contact_inbox.source_id, message.content)
    if source_id.present?
      message.update!(source_id: source_id)
      conversation.dispatch_conversation_updated_event
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
    message.update!(status: :failed, external_error: e.message.to_s.truncate(255))
  end
end
