class Instagram::TypingIndicatorService
  attr_reader :channel, :recipient_id

  def initialize(channel, recipient_id)
    @channel = channel
    @recipient_id = recipient_id
  end

  def enable
    # Tối ưu cho mobile: Đảm bảo đánh dấu tin nhắn đã xem trước khi gửi typing_on
    # Điều này quan trọng để typing indicator hoạt động trên di động theo Instagram API v22
    mark_seen_result = mark_seen

    # Tăng thời gian chờ để đảm bảo Instagram xử lý request mark_seen trên mobile
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

    # Tăng thời gian chờ để đảm bảo Instagram xử lý request mark_seen trên mobile
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

    # Cấu hình tối ưu cho Instagram Graph API v22 và mobile compatibility
    # Theo Instagram documentation: https://developers.facebook.com/docs/instagram-api/reference/ig-user/messages
    typing_params = {
      recipient: { id: recipient_id },
      sender_action: action.upcase, # Instagram API v22 yêu cầu uppercase: TYPING_ON, TYPING_OFF, MARK_SEEN
      messaging_type: 'RESPONSE' # Thêm messaging_type để tối ưu delivery trên mobile
    }

    begin
      # Tăng số lần retry cho mobile compatibility theo Instagram best practices
      attempts = 0
      max_attempts = 3 # Giảm xuống 3 để tránh rate limiting
      success = false
      last_error = nil

      while attempts < max_attempts && !success
        attempts += 1

        # Sử dụng Instagram Graph API v22 endpoint
        # Endpoint: POST https://graph.instagram.com/v22.0/{ig-user-id}/messages
        access_token = channel.access_token
        instagram_id = channel.instagram_id.presence || 'me'
        api_version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')

        response = HTTParty.post(
          "https://graph.instagram.com/#{api_version}/#{instagram_id}/messages",
          body: typing_params.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'Mooly.vn/1.0 Instagram Bot'
          },
          query: { access_token: access_token },
          timeout: 10 # Thêm timeout để tránh hang trên mobile networks
        )

        if response.success?
          success = true
          Rails.logger.info "Instagram::TypingIndicatorService: Successfully sent #{action} to Instagram #{api_version} for recipient #{recipient_id} (attempt #{attempts})"
        else
          error_body = JSON.parse(response.body) rescue {}
          error_code = error_body.dig('error', 'code') || response.code
          error_message = error_body.dig('error', 'message') || response.message
          last_error = "Code #{error_code}: #{error_message}"

          Rails.logger.warn "Instagram::TypingIndicatorService: Attempt #{attempts}/#{max_attempts} failed for #{action} to Instagram #{api_version}: #{last_error}"

          # Exponential backoff cho mobile compatibility
          sleep_time = [0.5 * (2 ** (attempts - 1)), 2.0].min
          sleep(sleep_time) if attempts < max_attempts
        end
      end

      unless success
        Rails.logger.error "Instagram::TypingIndicatorService: Failed to send #{action} after #{max_attempts} attempts. Last error: #{last_error}"
      end

      success
    rescue => e
      Rails.logger.error "Instagram::TypingIndicatorService: Exception sending typing indicator to Instagram v22: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      false
    end
  end

  # Phương thức legacy cho backward compatibility
  def send_typing_indicator(action)
    send_typing_indicator_with_retry(action)
  end

  def valid_action?(action)
    # Instagram API v22 hỗ trợ các sender actions (case-insensitive)
    valid_actions = %w[typing_on typing_off mark_seen TYPING_ON TYPING_OFF MARK_SEEN]
    return true if valid_actions.include?(action)

    Rails.logger.error "Instagram::TypingIndicatorService: Invalid action: #{action}. Valid actions: #{valid_actions.join(', ')}"
    false
  end

  def valid_channel?
    return true if channel.is_a?(Channel::Instagram)

    Rails.logger.error "Instagram::TypingIndicatorService: Invalid channel type: #{channel.class}"
    false
  end
end
