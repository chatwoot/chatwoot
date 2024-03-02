class Zalo::DeliveryStatusService
  pattr_initialize [:inbox!, :params!]

  def perform
    if params[:event_name] == 'user_received_message'
      received_message
    else
      seen_message
    end
  end

  private

  def received_message
    message = inbox.messages.find_by(source_id: params[:message][:msg_id])
    message&.update!(status: :delivered)
  end

  def seen_message
    message_ids = params[:message][:msg_ids]
    message_ids.each do |message_id|
      message = inbox.messages.find_by(source_id: message_id)
      message&.update!(status: :read)
    end
  end
end
