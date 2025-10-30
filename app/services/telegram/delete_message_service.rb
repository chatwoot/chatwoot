class Telegram::DeleteMessageService
  pattr_initialize [:message!]

  def perform
    return unless should_delete_from_telegram?

    delete_message_from_telegram
  rescue StandardError => e
    Rails.logger.error "Error while deleting telegram message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def should_delete_from_telegram?
    return false unless message.outgoing?
    return false unless message.source_id.present?
    return false unless message.inbox.channel_type == 'Channel::Telegram'
    return false unless message.content_attributes['deleted'] == true

    true
  end

  def delete_message_from_telegram
    channel = message.inbox.channel
    chat_id = message.conversation.additional_attributes['chat_id']
    business_connection_id = message.conversation.additional_attributes['business_connection_id']

    response = channel.delete_message_on_telegram(
      chat_id: chat_id,
      message_id: message.source_id,
      business_connection_id: business_connection_id
    )

    handle_response(response)
  end

  def handle_response(response)
    return if response.success?

    error_message = response.parsed_response['description'] || 'Unknown error'
    Rails.logger.error "Failed to delete Telegram message: #{error_message}"

    # Store error in message attributes for debugging
    message.update(
      content_attributes: message.content_attributes.merge(
        external_error: "Failed to delete on Telegram: #{error_message}"
      )
    )
  end
end
