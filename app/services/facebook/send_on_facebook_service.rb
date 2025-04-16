class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    # Gửi typing indicator trước khi gửi tin nhắn
    enable_typing_indicator

    if message.content_type == 'input_select'
      send_message_to_facebook(fb_select_message_params)
    elsif message.content_type == 'cards'
      send_message_to_facebook(fb_card_message_params)
    elsif message.content.present?
      send_message_to_facebook(fb_text_message_params)
    end

    if message.attachments.present?
      message.attachments.each do |attachment|
        send_message_to_facebook(fb_attachment_message_params(attachment))
      end
    end

    # Tắt typing indicator sau khi gửi tin nhắn
    disable_typing_indicator
  rescue Facebook::Messenger::FacebookError => e
    handle_facebook_error(e)
    message.update!(status: :failed, external_error: e.message)
  end

  def send_message_to_facebook(delivery_params)
    parsed_result = deliver_message(delivery_params)
    return if parsed_result.nil?

    if parsed_result['error'].present?
      message.update!(status: :failed, external_error: external_error(parsed_result))
      Rails.logger.info "Facebook::SendOnFacebookService: Error sending message to Facebook : Page - #{channel.page_id} : #{parsed_result}"
    end

    message.update!(source_id: parsed_result['message_id']) if parsed_result['message_id'].present?
  end

  def deliver_message(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    JSON.parse(result)
  rescue JSON::ParserError
    message.update!(status: :failed, external_error: 'Facebook was unable to process this request')
    Rails.logger.error "Facebook::SendOnFacebookService: Error parsing JSON response from Facebook : Page - #{channel.page_id} : #{result}"
    nil
  rescue Net::OpenTimeout
    message.update!(status: :failed, external_error: 'Request timed out, please try again later')
    Rails.logger.error "Facebook::SendOnFacebookService: Timeout error sending message to Facebook : Page - #{channel.page_id}"
    nil
  end

  # Sử dụng TypingIndicatorService
  def typing_service
    @typing_service ||= Facebook::TypingIndicatorService.new(channel, contact.get_source_id(inbox.id))
  end

  # Bật typing indicator
  def enable_typing_indicator
    return if contact.blank? || contact.get_source_id(inbox.id).blank?

    result = typing_service.enable
    if result
      Rails.logger.debug "Successfully enabled typing indicator for recipient #{contact.get_source_id(inbox.id)}"
    else
      Rails.logger.warn "Failed to enable typing indicator for recipient #{contact.get_source_id(inbox.id)}"
    end
  rescue => e
    Rails.logger.error "Error enabling typing indicator: #{e.message}"
  end

  # Tắt typing indicator
  def disable_typing_indicator
    return if contact.blank? || contact.get_source_id(inbox.id).blank?

    result = typing_service.disable
    if result
      Rails.logger.debug "Successfully disabled typing indicator for recipient #{contact.get_source_id(inbox.id)}"
    else
      Rails.logger.warn "Failed to disable typing indicator for recipient #{contact.get_source_id(inbox.id)}"
    end
  rescue => e
    Rails.logger.error "Error disabling typing indicator: #{e.message}"
  end

  def fb_text_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  def external_error(response)
    # https://developers.facebook.com/docs/graph-api/guides/error-handling/
    error_message = response['error']['message']
    error_code = response['error']['code']

    "#{error_code} - #{error_message}"
  end

  def fb_attachment_message_params(attachment)
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', conversation.last_incoming_message.id).count == 1
  end

  def handle_facebook_error(exception)
    error_message = exception.message

    if error_message.include?('The session has been invalidated') ||
       error_message.include?('Error validating access token') ||
       error_message.include?('Invalid OAuth access token')
      channel.authorization_error!
      raise exception
    end

    # Log lỗi chi tiết
    Rails.logger.error "Facebook::SendOnFacebookService Error: #{error_message}"

    # Cập nhật trạng thái message
    message.update!(
      status: :failed,
      external_error: "Facebook Error: #{error_message}"
    )
  end

  def fb_select_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'button',
            text: message.content,
            buttons: message.content_attributes['items'].map do |item|
              # Kiểm tra nếu value là một URL
              if item['value'].to_s.match?(/\A#{URI::DEFAULT_PARSER.make_regexp}\z/)
                {
                  type: 'web_url',
                  title: item['title'],
                  url: item['value']
                }
              else
                {
                  type: 'postback',
                  title: item['title'],
                  payload: item['value']
                }
              end
            end
          }
        }
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  def fb_card_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: message.content_attributes['items'].map do |item|
              {
                title: item['title'],
                subtitle: item['description'],
                image_url: item['media_url'],
                buttons: item['actions'].map do |action|
                  if action['type'] == 'link'
                    {
                      type: 'web_url',
                      title: action['text'],
                      url: action['uri']
                    }
                  else
                    {
                      type: 'postback',
                      title: action['text'],
                      payload: action['payload']
                    }
                  end
                end
              }
            end
          }
        }
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end
end