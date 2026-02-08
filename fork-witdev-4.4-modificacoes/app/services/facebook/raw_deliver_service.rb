class Facebook::RawDeliverService < Base::SendOnChannelService
  pattr_initialize [:message!, :payload!]

  private

  def channel_class
    Channel::FacebookPage
  end

  # Sends a raw payload (e.g., template with buttons) directly via Messenger API
  def perform_reply
    delivery_params = normalized_payload
    parsed_result = deliver_message(delivery_params)
    return if parsed_result.nil?

    if parsed_result['error'].present?
      Messages::StatusUpdateService.new(message, 'failed', external_error(parsed_result)).perform
      Rails.logger.info "Facebook::RawDeliverService: Error sending message to Facebook : Page - #{channel.page_id} : #{parsed_result}"
      return
    end

    message.update!(source_id: parsed_result['message_id']) if parsed_result['message_id'].present?
  rescue Facebook::Messenger::FacebookError => e
    handle_facebook_error(e)
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def normalized_payload
    p = payload.deep_dup

    # Ensure recipient is present (processor should add it, but double‑check)
    p['recipient'] ||= { 'id' => contact.get_source_id(inbox.id) }

    # Ensure required send context when not provided by upstream
    p['messaging_type'] ||= 'MESSAGE_TAG'
    p['tag'] ||= 'ACCOUNT_UPDATE'
    p
  end

  def deliver_message(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    JSON.parse(result)
  rescue JSON::ParserError
    Messages::StatusUpdateService.new(message, 'failed', 'Facebook was unable to process this request').perform
    Rails.logger.error "Facebook::RawDeliverService: Error parsing JSON response from Facebook : Page - #{channel.page_id} : #{result}"
    nil
  rescue Net::OpenTimeout
    Messages::StatusUpdateService.new(message, 'failed', 'Request timed out, please try again later').perform
    Rails.logger.error "Facebook::RawDeliverService: Timeout error sending message to Facebook : Page - #{channel.page_id}"
    nil
  end

  def external_error(response)
    error_message = response.dig('error', 'message')
    error_code = response.dig('error', 'code')
    [error_code, error_message].compact.join(' - ')
  end

  def handle_facebook_error(exception)
    return unless exception.to_s.include?('The session has been invalidated') ||
                  exception.to_s.include?('Error validating access token')

    channel.authorization_error!
  end
end

