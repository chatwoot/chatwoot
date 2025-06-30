class Zalo::Messages::LinkService < Zalo::Messages::BaseService
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
        file_type: :share,
        external_url: attachment.dig(:payload, :url) || attachment.dig(:payload, :thumbnail),
        fallback_title: attachment.dig(:payload, :title),
        meta: {
          thumb_url: attachment.dig(:payload, :thumbnail),
          description: attachment.dig(:payload, :description),
          original: attachment
        }
      )
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process attachments: #{e.message}")
    raise e
  end

  def need_process_attachments?
    message_attachments.present? && @message.attachments.empty?
  end
end
