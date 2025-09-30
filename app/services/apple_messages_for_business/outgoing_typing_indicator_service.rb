# frozen_string_literal: true

class AppleMessagesForBusiness::OutgoingTypingIndicatorService
  AMB_SERVER = 'https://mspgw.push.apple.com/v1'.freeze

  def initialize(channel:, destination_id:, action:)
    @channel = channel
    @destination_id = destination_id
    @action = action # :start or :end
  end

  def perform
    return { success: false, error: 'Invalid action' } unless valid_action?

    message_id = SecureRandom.uuid

    payload = {
      id: message_id,
      type: typing_message_type,
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      v: 1
    }

    response = send_to_apple_gateway(payload, message_id)

    if response.success?
      Rails.logger.info "[AMB TypingIndicator] #{@action} indicator sent successfully"
      { success: true, message_id: message_id }
    else
      Rails.logger.error "[AMB TypingIndicator] Failed to send #{@action} indicator: #{response.code} - #{response.body}"
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  rescue StandardError => e
    Rails.logger.error "[AMB TypingIndicator] Send failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def valid_action?
    %i[start end].include?(@action)
  end

  def typing_message_type
    @action == :start ? 'typing_start' : 'typing_end'
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    Rails.logger.info "[AMB TypingIndicator] Sending #{@action} indicator to #{@destination_id}"

    HTTParty.post(
      "#{AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 10
    )
  end
end