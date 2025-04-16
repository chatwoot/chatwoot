class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    # Gửi typing indicator trước khi gửi tin nhắn
    # Việc đánh dấu tin nhắn đã xem sẽ được xử lý tự động trong ChannelListener
    # khi gửi sự kiện typing_on
    enable_typing_indicator

    # Đợi một khoảng thời gian ngắn để typing indicator hiển thị trước khi gửi tin nhắn
    # Điều này giúp người dùng có thể thấy typing indicator trước khi nhận được tin nhắn
    sleep(1.0) # Đợi 1 giây để typing indicator hiển thị

    if message.content_type == 'input_select'
      send_message_to_facebook(fb_select_message_params)
    elsif message.content_type == 'cards'
      send_message_to_facebook(fb_card_message_params)
    elsif message.content.present?
      send_message_to_facebook(fb_text_message_params)
    end

    # Xử lý gửi hình ảnh tối ưu
    send_attachments_optimized if message.attachments.present?

    # Tắt typing indicator sau khi gửi tin nhắn
    disable_typing_indicator
  rescue Facebook::Messenger::FacebookError => e
    handle_facebook_error(e)
    message.update!(status: :failed, external_error: e.message)
  end

  # Phương thức mới để xử lý gửi hình ảnh tối ưu
  def send_attachments_optimized
    # Đối với các tin nhắn có nhiều hình ảnh, có thể cân nhắc việc xử lý bất đồng bộ ở đây
    # Hiện tại chúng ta vẫn xử lý tuần tự nhưng đã tối ưu bằng cách ưu tiên sử dụng external_url

    message.attachments.each do |attachment|
      # Ghi log để theo dõi loại URL được sử dụng
      if attachment.external_url.present?
        Rails.logger.info "Facebook::SendOnFacebookService: Using external_url for attachment #{attachment.id}"
      else
        Rails.logger.info "Facebook::SendOnFacebookService: Using download_url for attachment #{attachment.id}"
      end

      send_message_to_facebook(fb_attachment_message_params(attachment))
    end
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

    # Chỉ gửi typing indicator mà không tự động đánh dấu tin nhắn đã xem
    # Điều này giúp tránh hiểu nhầm khi bot không hoạt động (ví dụ: hết credit)
    # mark_seen_result = typing_service.mark_seen
    # sleep(0.3) if mark_seen_result

    # Bật typing indicator
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

  # Đánh dấu tin nhắn đã xem được xử lý tự động trong ChannelListener
  # khi gửi sự kiện typing_on, không cần gọi trực tiếp từ đây

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
    # Ưu tiên sử dụng external_url nếu có, giúp tối ưu hiệu năng vì không cần tải hình ảnh về Chatwoot trước
    attachment_url = if attachment.external_url.present?
                      attachment.external_url
                    else
                      attachment.download_url
                    end

    Rails.logger.info "Facebook::SendOnFacebookService: Sending attachment with URL: #{attachment_url}"

    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment_url
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