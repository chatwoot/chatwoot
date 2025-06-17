class Facebook::TypingIndicatorService
  attr_reader :channel, :recipient_id

  def initialize(channel, recipient_id)
    @channel = channel
    @recipient_id = recipient_id
  end

  def enable
    # Tối ưu cho mobile: Đảm bảo đánh dấu tin nhắn đã xem trước khi gửi typing_on
    # Điều này quan trọng để typing indicator hoạt động trên di động theo Facebook API v22
    mark_seen_result = mark_seen

    # Tăng thời gian chờ để đảm bảo Facebook xử lý request mark_seen trên mobile
    sleep(0.8) if mark_seen_result

    # Sau đó mới gửi typing indicator với retry logic
    send_typing_indicator('typing_on')
  end

  def disable
    send_typing_indicator('typing_off')
  end

  def mark_seen
    send_typing_indicator('mark_seen')
  end

  # Phương thức tối ưu để gửi cả mark_seen và typing_on cho mobile compatibility
  def mark_seen_and_typing
    return false unless valid_channel?
    return false if recipient_id.blank?

    # Bước 1: Đánh dấu tin nhắn đã xem với retry logic
    mark_seen_result = send_typing_indicator_with_retry('mark_seen')

    return false unless mark_seen_result

    # Tăng thời gian chờ để đảm bảo Facebook xử lý request mark_seen trên mobile
    sleep(1.0)

    # Bước 2: Gửi typing indicator với retry logic
    typing_result = send_typing_indicator_with_retry('typing_on')

    # Trả về true nếu cả hai bước đều thành công
    mark_seen_result && typing_result
  end

  private

  # Phương thức gửi typing indicator với retry logic tối ưu cho mobile
  def send_typing_indicator_with_retry(action)
    return false unless valid_action?(action)
    return false unless valid_channel?
    return false if recipient_id.blank?

    # Cấu hình tối ưu cho Facebook Messenger Platform API v22 và mobile compatibility
    # Theo Facebook documentation: https://developers.facebook.com/docs/messenger-platform/reference/send-api/
    typing_params = {
      recipient: { id: recipient_id },
      sender_action: action.upcase, # Facebook API v22 yêu cầu uppercase: TYPING_ON, TYPING_OFF, MARK_SEEN
      messaging_type: 'RESPONSE' # Thêm messaging_type để tối ưu delivery trên mobile
    }

    begin
      # Tăng số lần retry cho mobile compatibility theo Facebook best practices
      attempts = 0
      max_attempts = 3 # Giảm xuống 3 để tránh rate limiting
      success = false
      last_error = nil

      while attempts < max_attempts && !success
        attempts += 1

        # Sử dụng Facebook Graph API v22 endpoint với page access token
        # Endpoint: POST https://graph.facebook.com/v22.0/me/messages
        result = Facebook::Messenger::Bot.deliver(
          typing_params,
          page_id: channel.page_id,
          access_token: channel.page_access_token
        )

        parsed_result = result.is_a?(String) ? JSON.parse(result) : result

        if parsed_result && parsed_result['error'].present?
          error_code = parsed_result['error']['code'] || 'unknown'
          error_message = parsed_result['error']['message'] || 'Unknown error'
          last_error = "Code #{error_code}: #{error_message}"

          Rails.logger.warn "Facebook::TypingIndicatorService: Attempt #{attempts}/#{max_attempts} failed for #{action} to Facebook v22: #{last_error}"

          # Exponential backoff cho mobile compatibility
          sleep_time = [0.5 * (2 ** (attempts - 1)), 2.0].min
          sleep(sleep_time) if attempts < max_attempts
        else
          success = true
          Rails.logger.info "Facebook::TypingIndicatorService: Successfully sent #{action} to Facebook v22 for recipient #{recipient_id} (attempt #{attempts})"
        end
      end

      unless success
        Rails.logger.error "Facebook::TypingIndicatorService: Failed to send #{action} after #{max_attempts} attempts. Last error: #{last_error}"
      end

      success
    rescue => e
      Rails.logger.error "Facebook::TypingIndicatorService: Exception sending typing indicator to Facebook v22: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      false
    end
  end

  # Phương thức legacy cho backward compatibility
  def send_typing_indicator(action)
    send_typing_indicator_with_retry(action)
  end

  def valid_action?(action)
    # Facebook API v22 hỗ trợ các sender actions (case-insensitive)
    valid_actions = %w[typing_on typing_off mark_seen TYPING_ON TYPING_OFF MARK_SEEN]
    return true if valid_actions.include?(action)

    Rails.logger.error "Facebook::TypingIndicatorService: Invalid action: #{action}. Valid actions: #{valid_actions.join(', ')}"
    false
  end

  def valid_channel?
    return true if channel.is_a?(Channel::FacebookPage)

    Rails.logger.error "Facebook::TypingIndicatorService: Invalid channel type: #{channel.class}"
    false
  end
end