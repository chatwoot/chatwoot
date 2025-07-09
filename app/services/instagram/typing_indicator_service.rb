class Instagram::TypingIndicatorService
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

    # Cấu hình đơn giản theo Instagram Graph API v22
    typing_params = {
      recipient: { id: recipient_id },
      sender_action: action.downcase # Instagram API v22 yêu cầu lowercase: typing_on, typing_off, mark_seen
    }

    begin
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
        timeout: 10
      )

      if response.success?
        Rails.logger.info "Instagram::TypingIndicatorService: Successfully sent #{action} to Instagram for recipient #{recipient_id}"
        true
      else
        error_body = JSON.parse(response.body) rescue {}
        error_code = error_body.dig('error', 'code') || response.code
        error_message = error_body.dig('error', 'message') || response.message
        Rails.logger.error "Instagram::TypingIndicatorService: Failed to send #{action} - Code #{error_code}: #{error_message}"
        false
      end
    rescue => e
      Rails.logger.error "Instagram::TypingIndicatorService: Exception sending #{action}: #{e.message}"
      false
    end
  end

  def valid_action?(action)
    %w[typing_on typing_off mark_seen].include?(action.downcase)
  end

  def valid_channel?
    channel.is_a?(Channel::Instagram) && channel.access_token.present?
  end
end
