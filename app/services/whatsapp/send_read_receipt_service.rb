class Whatsapp::SendReadReceiptService
  pattr_initialize [:message!]

  def perform
    return unless should_send_read_receipt?

    channel.provider_service.mark_as_read(message)
  end

  private

  def channel
    @channel ||= message.inbox.channel
  end

  def should_send_read_receipt?
    message.incoming? &&
      channel.is_a?(Channel::Whatsapp) &&
      channel.provider == 'whapi' &&
      message.source_id.present?
  end
end