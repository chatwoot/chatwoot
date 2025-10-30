class Telegram::EditMessageService
  pattr_initialize [:message!]

  def perform
    return unless should_edit_on_telegram?

    edit_message_on_telegram
  rescue StandardError => e
    Rails.logger.error "Error while editing telegram message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def should_edit_on_telegram?
    return false unless message.outgoing?
    return false unless message.source_id.present?
    return false unless message.inbox.channel_type == 'Channel::Telegram'
    return false unless message.saved_change_to_content?

    true
  end

  def edit_message_on_telegram
    channel = message.inbox.channel
    chat_id = message.conversation.additional_attributes['chat_id']
    business_connection_id = message.conversation.additional_attributes['business_connection_id']

    response = channel.edit_message_on_telegram(
      chat_id: chat_id,
      message_id: message.source_id,
      text: message.content,
      business_connection_id: business_connection_id
    )

    handle_response(response)
  end

  def handle_response(response)
    return if response.success?

    error_message = response.parsed_response.dig('description') || 'Unknown error'
    Rails.logger.error "Failed to edit Telegram message: #{error_message}"

    # Update message with error if needed
    message.update(
      content_attributes: message.content_attributes.merge(
        external_error: "Failed to edit on Telegram: #{error_message}"
      )
    )
  end
end
