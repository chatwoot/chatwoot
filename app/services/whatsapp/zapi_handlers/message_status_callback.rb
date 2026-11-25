module Whatsapp::ZapiHandlers::MessageStatusCallback
  include Whatsapp::ZapiHandlers::Helpers

  private

  def process_message_status_callback
    status = map_zapi_status_to_chatwoot(processed_params[:status])
    return unless status

    processed_params[:ids].each do |message_id|
      message = inbox.messages.find_by(source_id: message_id)
      next unless message

      # Messages::StatusUpdateService refuses a move backwards and clears the external_error
      # of a message that leaves `failed`, but lets any message become `failed`, and a
      # message the contact has read cannot have failed.
      Messages::StatusUpdateService.new(message, status).perform unless message.status == 'read'
    end
  end

  def map_zapi_status_to_chatwoot(zapi_status)
    case zapi_status.upcase
    when 'SENT'
      :sent
    when 'DELIVERED', 'RECEIVED'
      :delivered
    when 'READ', 'READ_BY_ME', 'PLAYED'
      :read
    when 'FAILED'
      :failed
    else
      Rails.logger.warn "Unknown ZAPI status: #{zapi_status}"
      nil
    end
  end
end
