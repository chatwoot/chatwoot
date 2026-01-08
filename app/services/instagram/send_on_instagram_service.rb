class Instagram::SendOnInstagramService < Base::SendOnChannelService
  include HTTParty

  pattr_initialize [:message!]

  base_uri 'https://graph.facebook.com/v18.0'

  private

  def channel_class
    Channel::Instagram
  end

  def perform_reply
    if message.attachments.present?
      send_to_instagram_page attachment_message_params
    else
      send_to_instagram_page message_params
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account, user: message.sender).capture_exception
  end

  def message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.content
      }
    }.tap { |params| merge_human_agent_tag(params) }
  end

  def attachment_message_params
    attachment = message.attachments.first
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }.tap { |params| merge_human_agent_tag(params) }
  end

  def send_to_instagram_page(message_content)
    access_token = channel.access_token
    query = { access_token: access_token }

    if conversation.additional_attributes['type'] == 'instagram_comments'

      send_reply_to_instagram_comment(query, message_content)
    else
      send_message_to_instagram(query, message_content)
    end
  end

  def send_reply_to_instagram_comment(query, message_content)
    comment_id = conversation.additional_attributes['comment_id']
    url = "https://graph.instagram.com/v23.0/#{comment_id}/replies"

    response = HTTParty.post(
      url,
      body: {
        message: message_content[:message][:text],
        access_token: query[:access_token]
      }
    )
    handle_response(response)
  end

  def send_message_to_instagram(query, message_content)
    url = 'https://graph.instagram.com/v23.0/me/messages'
    response = HTTParty.post(
      url,
      body: message_content,
      query: query
    )

    handle_response(response)
  end

  def handle_response(response)
    if response['error'].present?
      Rails.logger.error("Instagram response: #{response['error']} : #{message.content}")
      message.status = :failed
      message.mark_failed!(external_error(response))
    else
      message.source_id = response['id'] || response['message_id'] if response['id'].present? || response['message_id'].present?

      message.mark_sent!
      enqueue_next_message
    end
  end

  def enqueue_next_message
    next_msg = conversation.messages
                           .where('id > ?', message.id)
                           .where("additional_attributes ->> 'delivery_status' = ?", 'pending')
                           .order(:id)
                           .first

    return unless next_msg.present?

    SendReplyJob.perform_later(next_msg.id)
  end

  def external_error(response)
    error_message = response['error']['message']
    error_code = response['error']['code']
    "#{error_code} - #{error_message}"
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
    return params unless global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']

    params[:messaging_type] = 'MESSAGE_TAG'
    params[:tag] = 'HUMAN_AGENT'
    params
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include?(attachment.file_type)

    'file'
  end

  def contact
    @contact ||= begin
      conv = message.conversation
      raise "❌ Conversation not found for message ID #{message.id}" unless conv
      raise "❌ Contact not found for conversation ID #{conv.id}" unless conv.contact

      conv.contact
    end
  end

  def inbox
    @inbox ||= begin
      raise "❌ Inbox not found for message ID #{message.id}" unless message.inbox

      message.inbox
    end
  end

  def channel
    @channel ||= inbox.channel
  end

  def conversation
    @conversation ||= begin
      raise "❌ Conversation not found for message ID #{message.id}" unless message.conversation

      message.conversation
    end
  end
end
