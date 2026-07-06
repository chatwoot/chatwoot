class AppStore::SendOnAppStoreService < Base::SendOnChannelService
  private

  def channel_class
    Channel::AppStore
  end

  def perform_reply
    validate_feature_enabled!
    validate_message_support!
    source_id = channel.reply_to_review(review_id, reply_content)
    sync_response_message(source_id)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def validate_message_support!
    raise 'Only outgoing text messages are supported for App Store reviews.' unless message.outgoing? && message.text?
    raise 'Sending attachments is not supported for App Store reviews.' if message.attachments.any?
  end

  def validate_feature_enabled!
    return if message.account.feature_enabled?(:channel_app_store)

    raise 'App Store Reviews channel is not enabled for this account.'
  end

  def review_id
    message.conversation.contact_inbox.source_id
  end

  def reply_content
    message.outgoing_content.presence || message.content
  end

  def existing_response_message(source_id)
    return if source_id.blank?

    message.conversation.messages.where.not(id: message.id).find_by(source_id: source_id)
  end

  def sync_response_message(source_id)
    response_message = existing_response_message(source_id)

    if response_message.present?
      update_existing_response_message(response_message, source_id)
      message.destroy!
      Messages::StatusUpdateService.new(response_message, 'delivered').perform
    else
      message.update!(source_id: source_id) if source_id.present?
      Messages::StatusUpdateService.new(message, 'delivered').perform
    end
  end

  def update_existing_response_message(response_message, source_id)
    content_attributes = (response_message.content_attributes || {}).deep_merge(
      'external_echo' => true,
      'app_store' => {
        'response_id' => source_id
      }
    )

    response_message.update!(content: reply_content, content_attributes: content_attributes)
  end
end
