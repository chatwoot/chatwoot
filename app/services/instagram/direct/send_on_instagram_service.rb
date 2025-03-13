class Instagram::Direct::SendOnInstagramService < Base::SendOnChannelService
  include HTTParty

  pattr_initialize [:message!]

  private

  delegate :additional_attributes, to: :contact

  def channel_class
    Channel::Instagram
  end

  def perform_reply
    Rails.logger.info("Sending message to Instagram: #{message.inspect}")
    if message.attachments.present?
      message.attachments.each do |attachment|
        send_to_instagram attachment_message_params(attachment)
      end
    end

    send_to_instagram message_params if message.content.present?
  rescue StandardError => e
    Rails.logger.info("Instagram Error: #{e.inspect}")
    ChatwootExceptionTracker.new(e, account: message.account, user: message.sender).capture_exception
    # TODO : handle specific auth errors
    # channel.authorization_error!
  end

  def message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.content
      }
    }

    merge_human_agent_tag(params)
  end

  def attachment_message_params(attachment)
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }

    merge_human_agent_tag(params)
  end

  # Deliver a message with the given payload.
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
  def send_to_instagram(message_content)
    access_token = channel.access_token

    query = { access_token: access_token }

    instagram_id = channel.instagram_id.presence || 'me'

    response = HTTParty.post(
      "https://graph.instagram.com/v22.0/#{instagram_id}/messages",
      body: message_content,
      query: query
    )

    Rails.logger.info("I.G:response #{response}")

    if response[:error].present?
      Rails.logger.error("Instagram response: #{response['error']} : #{message_content}")
      message.status = :failed
      message.external_error = external_error(response)
    end

    Rails.logger.info("Instagram response: #{response.inspect}")

    handle_response(response, message_content)
  end

  def handle_response(response, message_content)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['error'].blank?
      message.update!(source_id: parsed_response['message_id'])

      parsed_response
    else
      external_error = external_error(parsed_response)
      Rails.logger.error("Instagram response: #{external_error} : #{message_content}")
      message.update!(status: :failed, external_error: external_error)

      nil
    end
  end

  def external_error(response)
    # https://developers.facebook.com/docs/instagram-api/reference/error-codes/
    error_message = response.dig('error', 'message')
    error_code = response.dig('error', 'code')

    "#{error_code} - #{error_message}"
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def conversation_type
    conversation.additional_attributes['type']
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')

    return params unless global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']
    return params unless should_add_human_agent_tag?

    # Add human agent tag to enable responses outside the standard 24-hour window
    # This allows human agents to respond within 7 days of the last user message
    # Requires business verification and app review approval
    params[:messaging_type] = 'MESSAGE_TAG'
    params[:tag] = 'human_agent'
    params
  end

  # Determines if the human agent tag should be added to the message
  # @return [Boolean] true if the message qualifies for human agent tag
  def should_add_human_agent_tag?
    return false unless conversation.last_incoming_message

    # Instagram allows human agent responses within 7 days of the last user message
    # https://developers.facebook.com/docs/features-reference/human-agent
    seven_days_ago = 7.days.ago
    conversation.last_incoming_message.created_at > seven_days_ago
  end
end
