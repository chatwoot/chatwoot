class Zalo::Messages::BusinessCardService < Zalo::Messages::BaseService

  private

  def message_content
    nil
  end

  def content_type
    :text
  end

  def process_attachments
    return unless need_process_attachments?

    message_attachments.each do |message_attachment|
      @message_attachment = message_attachment
      new_attachment = @message.attachments.find_or_initialize_by(
        account_id: account.id,
        file_type: :contact,
        fallback_title: phone_number
      )
      new_attachment.external_url ||= @message_attachment.dig(:payload, :url)
      new_attachment.external_url ||= @message_attachment.dig(:payload, :thumbnail)
      new_attachment.meta = {
        original: @message_attachment,
        first_name: contact_name,
        qr_code_url: qr_code_url,
        avatar_url: message_attachment.dig(:payload, :thumbnail),
      }
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process attachments: #{e.message}")
    raise e
  end

  def need_process_attachments?
    message_attachments.present? && @message.attachments.empty?
  end

  def phone_number
    payload_description['phone']
  rescue StandardError => e
    Rails.logger.error("Failed to extract phone number: #{e.message}")
    ''
  end

  def qr_code_url
    payload_description['qrCodeUrl']
  rescue StandardError => e
    Rails.logger.error("Failed to extract QR code URL: #{e.message}")
    ''
  end

  def contact_name
    params.dig(:message, :text)
  end

  def payload_description
    JSON.parse(@message_attachment.dig(:payload, :description) || '{}')
  rescue JSON::ParserError
    {}
  end
end
