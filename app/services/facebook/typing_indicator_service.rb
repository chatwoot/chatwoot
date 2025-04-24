class Facebook::TypingIndicatorService
  attr_reader :channel, :recipient_id

  def initialize(channel, recipient_id)
    @channel = channel
    @recipient_id = recipient_id
  end

  def enable
    # Đảm bảo đánh dấu tin nhắn đã xem trước khi gửi typing_on
    # Điều này quan trọng để typing indicator hoạt động trên di động
    mark_seen_result = mark_seen

    # Đợi một khoảng thời gian ngắn để Facebook xử lý request mark_seen
    sleep(0.5) if mark_seen_result

    # Sau đó mới gửi typing indicator
    send_typing_indicator('typing_on')
  end

  def disable
    send_typing_indicator('typing_off')
  end

  def mark_seen
    send_typing_indicator('mark_seen')
  end

  # Phương thức mới để gửi cả mark_seen và typing_on trong một chuỗi
  def mark_seen_and_typing
    return false unless valid_channel?
    return false if recipient_id.blank?

    # Bước 1: Đánh dấu tin nhắn đã xem
    mark_seen_result = mark_seen

    # Đợi một khoảng thời gian ngắn để Facebook xử lý request mark_seen
    sleep(0.5) if mark_seen_result

    # Bước 2: Gửi typing indicator
    typing_result = send_typing_indicator('typing_on')

    # Trả về true nếu cả hai bước đều thành công
    mark_seen_result && typing_result
  end

  private

  def send_typing_indicator(action)
    return false unless valid_action?(action)
    return false unless valid_channel?
    return false if recipient_id.blank?

    # Sử dụng messaging_type phù hợp theo tài liệu Facebook
    # RESPONSE: Sử dụng cho phản hồi trong vòng 24 giờ sau tin nhắn của người dùng
    # MESSAGE_TAG: Sử dụng cho tin nhắn ngoài cửa sổ 24 giờ với tag phù hợp
    typing_params = {
      recipient: { id: recipient_id },
      sender_action: action
    }

    # Không cần messaging_type cho sender_action theo tài liệu mới nhất của Facebook
    # Điều này giúp đảm bảo typing indicator hoạt động trên mọi thiết bị

    begin
      # Thêm retry logic để tăng độ tin cậy
      attempts = 0
      max_attempts = 3
      success = false

      while attempts < max_attempts && !success
        attempts += 1

        result = Facebook::Messenger::Bot.deliver(typing_params, page_id: channel.page_id)
        parsed_result = result.is_a?(String) ? JSON.parse(result) : result

        if parsed_result && parsed_result['error'].present?
          error_code = parsed_result['error']['code'] || 'unknown'
          error_message = parsed_result['error']['message'] || 'Unknown error'
          Rails.logger.error "Facebook::TypingIndicatorService: Error sending #{action} to Facebook: Code #{error_code} - #{error_message}"

          # Đợi trước khi thử lại
          sleep(0.5) if attempts < max_attempts
        else
          success = true
          Rails.logger.debug "Facebook::TypingIndicatorService: Successfully sent #{action} to Facebook for recipient #{recipient_id}"
        end
      end

      success
    rescue => e
      Rails.logger.error "Facebook::TypingIndicatorService: Error sending typing indicator to Facebook: #{e.message}"
      false
    end
  end

  def valid_action?(action)
    return true if %w[typing_on typing_off mark_seen].include?(action)

    Rails.logger.error "Facebook::TypingIndicatorService: Invalid action: #{action}"
    false
  end

  def valid_channel?
    return true if channel.is_a?(Channel::FacebookPage)

    Rails.logger.error "Facebook::TypingIndicatorService: Invalid channel type: #{channel.class}"
    false
  end
end