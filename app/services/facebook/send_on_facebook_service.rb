class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    # Kiểm tra và refresh token nếu cần trước khi gửi tin nhắn
    ensure_valid_token

    # Gửi typing indicator trước khi gửi tin nhắn
    # Sử dụng phương thức mới mark_seen_and_typing để đảm bảo typing hoạt động trên di động
    enable_typing_indicator

    # Đợi một khoảng thời gian ngắn để typing indicator hiển thị trước khi gửi tin nhắn
    # Điều này giúp người dùng có thể thấy typing indicator trước khi nhận được tin nhắn
    # Giảm thời gian chờ xuống 0.8 giây để tăng hiệu suất nhưng vẫn đảm bảo UX tốt
    sleep(0.8)

    # Xử lý gửi tin nhắn và tệp đính kèm
    send_message_content
    send_attachments_optimized if message.attachments.present?

    # Tắt typing indicator sau khi gửi tin nhắn
    disable_typing_indicator

    # Cập nhật trạng thái tin nhắn thành công nếu không có lỗi
    message.update!(status: :delivered) if message.status == 'sent'
  rescue Facebook::Messenger::FacebookError => e
    handle_facebook_error(e)
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  # Tách riêng việc gửi nội dung tin nhắn để code rõ ràng hơn
  def send_message_content
    # Đo thời gian gửi tin nhắn để theo dõi hiệu suất
    start_time = Time.now

    if message.content_type == 'input_select'
      send_message_to_facebook(fb_select_message_params)
    elsif message.content_type == 'cards'
      send_message_to_facebook(fb_card_message_params)
    elsif message.content.present?
      send_message_to_facebook(fb_text_message_params)
    end

    # Ghi log thời gian gửi tin nhắn
    Rails.logger.info "Facebook::SendOnFacebookService: Sent message content in #{(Time.now - start_time).round(2)}s"
  end

  # Phương thức tối ưu để xử lý gửi hình ảnh
  def send_attachments_optimized
    start_time = Time.now
    attachment_count = message.attachments.size

    # Nếu chỉ có 1 tệp đính kèm, gửi trực tiếp
    if attachment_count == 1
      attachment = message.attachments.first
      send_single_attachment(attachment)
      return
    end

    # Nếu có nhiều tệp đính kèm, sử dụng batch processing
    # Để tránh gửi quá nhiều request liên tiếp đến Facebook API
    # chúng ta sẽ gửi các tệp đính kèm với một khoảng thời gian ngắn giữa các lần gửi

    message.attachments.each_with_index do |attachment, index|
      # Gửi tệp đính kèm
      send_single_attachment(attachment)

      # Đợi một khoảng thời gian ngắn giữa các lần gửi
      # trừ khi đây là tệp đính kèm cuối cùng
      sleep(0.3) if index < attachment_count - 1
    end

    # Ghi log thời gian gửi tất cả các tệp đính kèm
    Rails.logger.info "Facebook::SendOnFacebookService: Sent #{attachment_count} attachments in #{(Time.now - start_time).round(2)}s"
  end

  # Gửi một tệp đính kèm duy nhất
  def send_single_attachment(attachment)
    # Đo thời gian gửi từng tệp đính kèm
    start_time = Time.now

    # Ghi log để theo dõi loại URL được sử dụng
    if attachment.external_url.present?
      Rails.logger.info "Facebook::SendOnFacebookService: Using external_url for attachment #{attachment.id}"
    else
      Rails.logger.info "Facebook::SendOnFacebookService: Using download_url for attachment #{attachment.id}"
    end

    # Gửi tệp đính kèm đến Facebook
    send_message_to_facebook(fb_attachment_message_params(attachment))

    # Ghi log thời gian gửi từng tệp đính kèm
    Rails.logger.info "Facebook::SendOnFacebookService: Sent attachment #{attachment.id} in #{(Time.now - start_time).round(2)}s"
  end

  def send_message_to_facebook(delivery_params)
    parsed_result = deliver_message(delivery_params)
    return if parsed_result.nil?

    if parsed_result['error'].present?
      Messages::StatusUpdateService.new(message, 'failed', external_error(parsed_result)).perform
      Rails.logger.info "Facebook::SendOnFacebookService: Error sending message to Facebook : Page - #{channel.page_id} : #{parsed_result}"
    end

    message.update!(source_id: parsed_result['message_id']) if parsed_result['message_id'].present?
  end

  def deliver_message(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    JSON.parse(result)
  rescue JSON::ParserError
    Messages::StatusUpdateService.new(message, 'failed', 'Facebook was unable to process this request').perform
    Rails.logger.error "Facebook::SendOnFacebookService: Error parsing JSON response from Facebook : Page - #{channel.page_id} : #{result}"
    nil
  rescue Net::OpenTimeout
    Messages::StatusUpdateService.new(message, 'failed', 'Request timed out, please try again later').perform
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

    # Sử dụng phương thức mới mark_seen_and_typing để đảm bảo đánh dấu tin nhắn đã xem trước
    # và sau đó mới gửi typing indicator, điều này quan trọng để typing hoạt động trên di động
    result = typing_service.mark_seen_and_typing

    if result
      Rails.logger.debug "Successfully enabled mark_seen and typing indicator for recipient #{contact.get_source_id(inbox.id)}"
    else
      # Nếu không thành công với mark_seen_and_typing, thử lại chỉ với typing_on
      typing_result = typing_service.enable
      if typing_result
        Rails.logger.debug "Successfully enabled typing indicator (without mark_seen) for recipient #{contact.get_source_id(inbox.id)}"
      else
        Rails.logger.warn "Failed to enable typing indicator for recipient #{contact.get_source_id(inbox.id)}"
      end
    end
  rescue => e
    Rails.logger.error "Error enabling typing indicator: #{e.message}"
    # Ghi log chi tiết hơn để debug
    Rails.logger.error e.backtrace.join("\n")
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
    # Ghi log chi tiết hơn để debug
    Rails.logger.error e.backtrace.join("\n")
  end

  # Đánh dấu tin nhắn đã xem được xử lý tự động trong ChannelListener
  # khi gửi sự kiện typing_on, không cần gọi trực tiếp từ đây

  def fb_text_message_params
    # Xác định messaging_type và tag phù hợp
    messaging_params = determine_messaging_params

    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content },
      messaging_type: messaging_params[:messaging_type],
      tag: messaging_params[:tag]
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

    # Thêm cache buster vào URL để tránh cache của Facebook
    # Điều này đặc biệt quan trọng khi gửi cùng một hình ảnh nhiều lần
    attachment_url = add_cache_buster(attachment_url)

    Rails.logger.info "Facebook::SendOnFacebookService: Sending attachment with URL: #{attachment_url}"

    # Xác định messaging_type và tag phù hợp
    messaging_params = determine_messaging_params

    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment_url,
            is_reusable: true # Cho phép Facebook cache lại attachment để tái sử dụng
          }
        }
      },
      messaging_type: messaging_params[:messaging_type],
      tag: messaging_params[:tag]
    }
  end

  # Thêm cache buster vào URL
  def add_cache_buster(url)
    return url if url.blank?

    separator = url.include?('?') ? '&' : '?'
    "#{url}#{separator}cache_buster=#{Time.now.to_i}"
  end

  # Xác định messaging_type và tag phù hợp dựa trên thời gian cuối cùng người dùng gửi tin nhắn
  def determine_messaging_params
    # Kiểm tra xem cuộc hội thoại có tin nhắn đến trong vòng 24 giờ không
    last_incoming_message = conversation.messages.incoming.order(created_at: :desc).first

    if last_incoming_message.present? && last_incoming_message.created_at > 24.hours.ago
      # Trong cửa sổ 24 giờ, sử dụng RESPONSE
      { messaging_type: 'RESPONSE', tag: nil }
    else
      # Ngoài cửa sổ 24 giờ, sử dụng MESSAGE_TAG với tag phù hợp
      { messaging_type: 'MESSAGE_TAG', tag: 'ACCOUNT_UPDATE' }
    end
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', conversation.last_incoming_message.id).count == 1
  end

  # Kiểm tra và đảm bảo token hợp lệ trước khi gửi tin nhắn
  def ensure_valid_token
    refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)

    # Kiểm tra token hiện tại
    unless refresh_service.token_valid?
      Rails.logger.warn("Invalid Facebook token detected for page #{channel.page_id}, attempting refresh")

      # Thử refresh token
      refreshed_token = refresh_service.attempt_token_refresh

      # Kiểm tra lại sau khi refresh
      unless refresh_service.token_valid?
        Rails.logger.error("Failed to refresh Facebook token for page #{channel.page_id}")
        raise Facebook::Messenger::FacebookError.new("Token refresh failed - manual reauthorization required")
      else
        Rails.logger.info("Successfully refreshed Facebook token for page #{channel.page_id}")
      end
    end
  end

  def handle_facebook_error(exception)
    error_message = exception.message

    # Kiểm tra các loại lỗi token khác nhau
    token_error_patterns = [
      'The session has been invalidated',
      'Error validating access token',
      'Invalid OAuth access token',
      'OAuthException',
      'The user has not authorized application',
      'Token refresh failed'
    ]

    if token_error_patterns.any? { |pattern| error_message.include?(pattern) }
      Rails.logger.error("Facebook token error detected: #{error_message}")
      channel.authorization_error!

      # Thử refresh token một lần nữa nếu chưa thử
      unless error_message.include?('Token refresh failed')
        begin
          refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
          refresh_service.attempt_token_refresh
        rescue StandardError => refresh_error
          Rails.logger.error("Final token refresh attempt failed: #{refresh_error.message}")
        end
      end

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