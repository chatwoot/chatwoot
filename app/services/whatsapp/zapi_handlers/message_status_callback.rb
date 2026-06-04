module Whatsapp::ZapiHandlers::MessageStatusCallback
  include Whatsapp::ZapiHandlers::Helpers

  private

  def process_message_status_callback
    status = map_zapi_status_to_chatwoot(processed_params[:status])
    return unless status

    processed_params[:ids].each do |message_id|
      message = inbox.messages.find_by(source_id: message_id)
      next unless message

      message.update!(status: status) if status_transition_allowed?(message, status.to_s)
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

  def status_transition_allowed?(message, new_status)
    return false if message.status == 'read'
    return false if message.status == 'delivered' && new_status == 'sent'

    true
  end
end
