# frozen_string_literal: true

# Evolution::SendOnEvolutionBaileysService
#
# Handles outbound message sending for Evolution Baileys WhatsApp inboxes.
# Routes all messages through Evolution API.
#
class Evolution::SendOnEvolutionBaileysService
  pattr_initialize [:message!]

  def perform
    return unless valid_message?

    if message.attachments.present?
      send_media_message
    else
      send_text_message
    end
  rescue EvolutionApi::Client::ApiError => e
    handle_api_error(e)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  private

  delegate :conversation, to: :message
  delegate :contact, :contact_inbox, :inbox, to: :conversation
  delegate :channel, to: :inbox

  def valid_message?
    return false unless inbox.evolution_inbox?
    return false unless message.outgoing? || message.template?
    return false if message.private?
    return false if message.source_id.present? # Avoid message loops

    true
  end

  def send_text_message
    Rails.logger.info("[Evolution Baileys] Sending text message to #{recipient_phone} via instance #{evolution_instance_name}")

    result = evolution_client.send_text(
      instance_name: evolution_instance_name,
      phone_number: recipient_phone,
      text: message.content
    )

    Rails.logger.info("[Evolution Baileys] Send result: #{result.inspect}")
    update_message_with_result(result)
  end

  def send_media_message
    attachment = message.attachments.first
    media_type = attachment_media_type(attachment)

    result = evolution_client.send_media(
      instance_name: evolution_instance_name,
      phone_number: recipient_phone,
      media_type: media_type,
      media_url: attachment.download_url,
      options: {
        caption: message.content,
        filename: attachment.file.filename.to_s
      }
    )

    update_message_with_result(result)
  end

  def attachment_media_type(attachment)
    case attachment.file_type
    when 'image' then 'image'
    when 'video' then 'video'
    when 'audio' then 'audio'
    else 'document'
    end
  end

  def update_message_with_result(result)
    # Evolution API returns message ID in different formats
    # Sometimes it's an array, sometimes a hash
    response = result.is_a?(Array) ? result.first : result

    return message.update!(status: :sent) if response.blank?

    message_id = extract_message_id(response)

    if message_id.present?
      message.update!(source_id: message_id, status: :sent)
    else
      message.update!(status: :sent)
    end
  end

  def extract_message_id(response)
    return nil unless response.is_a?(Hash)

    # Try different response formats from Evolution API
    response.dig('key', 'id') ||
      response['messageId'] ||
      response['id'] ||
      response.dig('message', 'key', 'id')
  end

  def handle_api_error(error)
    Rails.logger.error("[Evolution Baileys] API error sending message: #{error.message}")
    Rails.logger.error("[Evolution Baileys] API error details - Status: #{error.status rescue 'N/A'}, Body: #{error.response_body rescue 'N/A'}")
    message.update!(
      status: :failed,
      external_error: error.message
    )
  end

  def handle_unexpected_error(error)
    Rails.logger.error("[Evolution Baileys] Unexpected error sending message: #{error.class.name} - #{error.message}")
    Rails.logger.error("[Evolution Baileys] Backtrace: #{error.backtrace&.first(10)&.join("\n")}")
    message.update!(
      status: :failed,
      external_error: "Unexpected error: #{error.message}"
    )
  end

  def recipient_phone
    # Use contact identifier (WhatsApp JID like "555198007929@s.whatsapp.net" or "group@g.us")
    # Fall back to phone_number if identifier is not available
    contact.identifier.presence || contact.phone_number&.gsub(/\D/, '')
  end

  def evolution_instance_name
    channel.additional_attributes&.dig('evolution_instance_name')
  end

  def evolution_client
    @evolution_client ||= EvolutionApi::Client.new
  end
end

