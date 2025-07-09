class Messages::AttachmentUpdateService
  attr_reader :message

  def initialize(message)
    @message = message
  end

  def perform
    return false unless message.present?
    return false unless message.attachments.present?

    # Kiểm tra xem có attachment nào cần cập nhật không
    needs_update = check_attachments_need_update

    if needs_update
      # Broadcast message update để UI hiển thị attachment mới
      broadcast_message_update
      Rails.logger.info "Messages::AttachmentUpdateService: Broadcasted update for message #{message.id} with #{message.attachments.count} attachments"
    end

    needs_update
  end

  private

  def check_attachments_need_update
    # Kiểm tra xem có attachment nào có data_url hợp lệ không
    message.attachments.any? do |attachment|
      attachment.external_url.present? || attachment.file.attached?
    end
  end

  def broadcast_message_update
    # Dispatch MESSAGE_UPDATED event để trigger real-time update
    Rails.configuration.dispatcher.dispatch(
      Events::Types::MESSAGE_UPDATED,
      Time.zone.now,
      message: message,
      performed_by: Current.executed_by,
      previous_changes: { 'attachments' => 'updated' }
    )
  end
end
