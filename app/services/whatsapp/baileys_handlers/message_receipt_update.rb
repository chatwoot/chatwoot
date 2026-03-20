module Whatsapp::BaileysHandlers::MessageReceiptUpdate
  include Whatsapp::BaileysHandlers::Helpers

  private

  def process_message_receipt_update
    receipts = processed_params[:data]
    receipts.each do |receipt|
      @message = nil
      @raw_message = receipt

      next handle_receipt_update if incoming?

      # NOTE: Shared lock with Whatsapp::SendOnWhatsappService
      # Avoids race conditions when sending messages.
      with_baileys_channel_lock_on_outgoing_message(inbox.channel.id) { handle_receipt_update }
    end
  end

  def handle_receipt_update
    return unless find_message_by_source_id(raw_message_id)

    new_status = receipt_status
    return if new_status.nil?
    return unless receipt_status_transition_allowed?(new_status)

    @message.update!(status: new_status)
  end

  def receipt_status
    'delivered' if @raw_message.dig(:receipt, :receiptTimestamp).present?
  end

  def receipt_status_transition_allowed?(new_status)
    return false if @message.status == 'read'
    return false if @message.status == 'delivered' && new_status == 'delivered'

    true
  end
end
