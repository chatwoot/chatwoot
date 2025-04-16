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

    typing_params = {
      recipient: { id: recipient_id },
      sender_action: action,
      messaging_type: 'RESPONSE' # Thêm messaging_type để tuân thủ các yêu cầu mới của Facebook
    }

    begin
      result = Facebook::Messenger::Bot.deliver(typing_params, page_id: channel.page_id)
      parsed_result = JSON.parse(result) if result.is_a?(String)

      if parsed_result && parsed_result['error'].present?
        error_code = parsed_result['error']['code'] || 'unknown'
        error_message = parsed_result['error']['message'] || 'Unknown error'
        Rails.logger.error "Facebook::TypingIndicatorService: Error sending typing indicator to Facebook: Code #{error_code} - #{error_message}"
        return false
      end

      Rails.logger.debug "Facebook::TypingIndicatorService: Successfully sent #{action} to Facebook for recipient #{recipient_id}"
      true
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