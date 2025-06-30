class Zalo::Messages::AttachmentService < Zalo::Messages::BaseService
  private

  def message_content
    nil
  end

  def content_type
    :text
  end

  def process_attachments
    return unless need_process_attachments?

    message_attachments.each do |attachment|
      @message.attachments.find_or_initialize_by(
        account_id: account.id,
        external_url: attachment.dig(:payload, :url) || attachment.dig(:payload, :thumbnail),
        file_type: get_filetype(attachment),
        meta: { original: attachment }
      )
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process attachments: #{e.message}")
    raise e
  end

  def get_filetype(attachment)
    filetype = [attachment[:type].presence, attachment.dig(:payload, :type).presence].compact.join('.')
    {
      'file.mp4' => 'video',
      'file.gif' => 'image',
      'gif' => 'image',
      'image' => 'image',
      'audio' => 'audio'
    }[filetype] || 'file'
  end

  def need_process_attachments?
    message_attachments.present? && @message.attachments.empty?
  end
end
