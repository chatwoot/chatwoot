class X::SendOnXService < Base::SendOnChannelService
  private

  def channel_class
    Channel::X
  end

  def perform_reply
    ensure_valid_token!
    message_result = send_message
    source_id = extract_source_id(message_result)
    message.update!(source_id: source_id)
    Messages::StatusUpdateService.new(message, 'delivered').perform
  rescue X::Errors::UnauthorizedError => e
    handle_send_error(e, 'Authorization failed') { channel.authorization_error! }
  rescue X::Errors::RateLimitError => e
    handle_send_error(e, 'Rate limit exceeded')
  rescue StandardError => e
    handle_send_error(e, e.message)
  end

  def handle_send_error(error, error_message, &block)
    Rails.logger.error "X send error for channel #{channel.id}: #{error.message}"
    block&.call
    Messages::StatusUpdateService.new(message, 'failed', error_message).perform
  end

  def ensure_valid_token!
    X::TokenService.new(channel: channel).access_token
  end

  def send_message
    if tweet_reply?
      send_tweet_reply
    else
      send_direct_message
    end
  end

  def send_direct_message
    x_user_id = contact_inbox.source_id
    attachment = process_dm_attachment

    x_client.send_direct_message(
      participant_id: x_user_id,
      text: message.outgoing_content || '',
      attachments: attachment ? [{ media_id: attachment }] : nil
    )
  end

  def send_tweet_reply
    reply_to_tweet_id = find_reply_to_tweet_id
    media_ids = process_tweet_attachments

    x_client.create_tweet(
      text: message.outgoing_content,
      reply_to_tweet_id: reply_to_tweet_id,
      media_ids: media_ids
    )
  end

  def process_dm_attachment
    return nil if message.attachments.empty?

    upload_media(message.attachments.first)
  end

  def process_tweet_attachments
    return nil if message.attachments.empty?

    message.attachments.first(4).map { |attachment| upload_media(attachment, context: :tweet) }
  end

  def upload_media(attachment, context: :dm)
    file = Down.download(attachment.download_url)
    mime_type = attachment.file.content_type

    result = x_client.upload_media(file, mime_type: mime_type, context: context)

    result['media_id_string']
  rescue StandardError => e
    Rails.logger.error "Failed to upload media to X: #{e.message}"
    raise
  end

  def tweet_reply?
    conversation = message.conversation
    conversation.additional_attributes&.dig('type') == 'tweet'
  end

  def extract_source_id(result)
    result.dig('data', 'id') || result.dig('data', 'dm_event_id') || result['dm_event_id'] || result['id']
  end

  def find_reply_to_tweet_id
    message.content_attributes&.dig('in_reply_to_external_id') || latest_conversation_tweet_id
  end

  def latest_conversation_tweet_id
    latest_tweet = message.conversation.messages
                          .where.not(source_id: [nil, ''])
                          .order(created_at: :desc)
                          .first
    latest_tweet&.source_id || message.conversation.additional_attributes&.dig('tweet_id')
  end

  def x_client
    @x_client ||= channel.client
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end
