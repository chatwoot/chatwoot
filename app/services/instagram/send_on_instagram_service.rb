class Instagram::SendOnInstagramService < Instagram::BaseSendService
  private

  # Instagram comment conversations reply publicly via the Comments API,
  # while DMs continue through the parent (messaging) flow.
  def perform_reply
    return send_comment_reply if instagram_comment_conversation?

    super
  end

  def instagram_comment_conversation?
    message.conversation.additional_attributes['type'] == 'instagram_comment'
  end

  def send_comment_reply
    # The Comments API only accepts text; attachment-only replies are unsupported.
    return mark_comment_reply_unsupported if message.content.blank?

    comment_id = reply_target_comment_id
    return if comment_id.blank?

    response = HTTParty.post(
      "https://graph.instagram.com/v22.0/#{comment_id}/replies",
      query: { access_token: channel.access_token },
      body: { message: message.outgoing_content }
    )
    process_comment_response(response)
  end

  def mark_comment_reply_unsupported
    Messages::StatusUpdateService.new(
      message, 'failed', 'Instagram comment replies support text only; attachments are not supported.'
    ).perform
  end

  # Reply to the latest incoming comment that already existed when this reply was
  # composed. Filtering by created_at avoids posting under a newer comment that
  # arrived while the reply sat in the SendReplyJob queue.
  # `reorder` (not `order`) is required to override Message's default_scope
  # `order(created_at: :asc)`, otherwise the newest comment is not picked first.
  # content_attributes is a `json` column, so Postgres `->>` is unreliable;
  # read the attributes in Ruby instead (works for both json and jsonb).
  def reply_target_comment_id
    comment = message.conversation.messages.incoming
                     .where(created_at: ..message.created_at)
                     .reorder(created_at: :desc)
                     .find { |msg| msg.content_attributes['type'] == 'instagram_comment' }
    comment&.content_attributes&.dig('instagram_comment_id')
  end

  def process_comment_response(response)
    parsed = response.parsed_response
    if response.success? && parsed['error'].blank?
      message.update!(source_id: parsed['id'])
    else
      error = external_error(parsed)
      Rails.logger.error("Instagram comment reply error: #{error} : message ##{message.id}")
      Messages::StatusUpdateService.new(message, 'failed', error).perform
    end
  end

  def channel_class
    Channel::Instagram
  end

  # Deliver a message with the given payload.
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
  def send_message(message_content)
    access_token = channel.access_token
    query = { access_token: access_token }
    instagram_id = channel.instagram_id.presence || 'me'

    response = HTTParty.post(
      "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}/#{instagram_id}/messages",
      body: message_content,
      query: query
    )

    process_response(response, message_content)
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')

    return params unless global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']

    params[:messaging_type] = 'MESSAGE_TAG'
    params[:tag] = 'HUMAN_AGENT'
    params
  end
end
