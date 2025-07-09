class Facebook::TypingIndicatorService
  attr_reader :channel, :recipient_id

  def initialize(channel, recipient_id)
    @channel = channel
    @recipient_id = recipient_id
  end

  def enable
    send_typing_indicator('typing_on')
  end

  def disable
    send_typing_indicator('typing_off')
  end

  def mark_seen
    send_typing_indicator('mark_seen')
  end

  private

  def send_typing_indicator(action)
    return false unless valid_action?(action)
    return false unless valid_channel?
    return false if recipient_id.blank?

    # Cấu hình tối ưu cho Facebook API v22 - đơn giản và chính xác
    typing_params = {
      recipient: { id: recipient_id },
      sender_action: action
      # Không cần messaging_type cho sender_action - Facebook API v22 tự động xử lý
    }

    begin
      result = Facebook::Messenger::Bot.deliver(typing_params, page_id: channel.page_id)

      # Xử lý response đơn giản
      if result.is_a?(String)
        parsed_result = JSON.parse(result) rescue nil

        if parsed_result&.dig('error')
          error_code = parsed_result['error']['code'] || 'unknown'
          error_message = parsed_result['error']['message'] || 'Unknown error'
          Rails.logger.error "Facebook::TypingIndicatorService: API Error #{error_code}: #{error_message} for recipient #{recipient_id}"
          return false
        end
      end

      Rails.logger.info "Facebook::TypingIndicatorService: Successfully sent #{action} to recipient #{recipient_id}"
      true
    rescue JSON::ParserError => e
      Rails.logger.error "Facebook::TypingIndicatorService: JSON parse error: #{e.message}"
      false
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "Facebook::TypingIndicatorService: Timeout error: #{e.message}"
      false
    rescue => e
      Rails.logger.error "Facebook::TypingIndicatorService: Unexpected error sending #{action}: #{e.message}"
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