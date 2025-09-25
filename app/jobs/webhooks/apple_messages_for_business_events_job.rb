class Webhooks::AppleMessagesForBusinessEventsJob < ApplicationJob
  queue_as :default

  def perform(channel_id, payload, headers)
    Rails.logger.info "[AMB Job] Starting job execution for channel #{channel_id}"
    Rails.logger.info "[AMB Job] Payload type: #{payload['type']}, ID: #{payload['id']}"
    
    channel = Channel::AppleMessagesForBusiness.find(channel_id)
    Rails.logger.info "[AMB Job] Found channel: #{channel.name} (MSP ID: #{channel.msp_id})"
    
    return unless channel_active?(channel)

    process_message_event(channel, payload, headers)
    Rails.logger.info "[AMB Job] Job completed successfully"
  rescue StandardError => e
    Rails.logger.error "[AMB Job] Apple Messages event processing failed: #{e.message}"
    Rails.logger.error "[AMB Job] Backtrace: #{e.backtrace.join("\n")}"
    raise e # Re-raise to ensure job failure is tracked
  end

  private

  def channel_active?(channel)
    if channel&.account&.active?
      Rails.logger.info "[AMB Job] Channel and account are active"
      return true
    end

    Rails.logger.error "[AMB Job] Inactive channel or account for MSP ID: #{channel&.msp_id}"
    false
  end

  def process_message_event(channel, payload, headers)
    message_type = payload['type']
    Rails.logger.info "[AMB Job] Processing message type: #{message_type}"

    case message_type
    when 'text', 'interactive'
      Rails.logger.info "[AMB Job] Calling IncomingMessageService for #{message_type} message"
      AppleMessagesForBusiness::IncomingMessageService.new(
        inbox: channel.inbox,
        params: payload,
        headers: headers
      ).perform
      Rails.logger.info "[AMB Job] IncomingMessageService completed"
    when 'typing_start'
      Rails.logger.info "[AMB Job] Processing typing start indicator"
      process_typing_indicator(channel, payload, headers, :start)
    when 'typing_end'
      Rails.logger.info "[AMB Job] Processing typing end indicator"
      process_typing_indicator(channel, payload, headers, :end)
    when 'close'
      Rails.logger.info "[AMB Job] Processing conversation close"
      process_conversation_close(channel, payload, headers)
    else
      Rails.logger.error "[AMB Job] Unknown message type: #{message_type}"
    end
  end

  def process_typing_indicator(channel, payload, headers, status)
    # Create activity message for typing indicators
    AppleMessagesForBusiness::TypingIndicatorService.new(
      inbox: channel.inbox,
      params: payload,
      headers: headers,
      status: status
    ).perform
  end

  def process_conversation_close(channel, payload, headers)
    # Handle conversation close events
    AppleMessagesForBusiness::ConversationCloseService.new(
      inbox: channel.inbox,
      params: payload,
      headers: headers
    ).perform
  end
end