class SdkPush::DispatchService
  pattr_initialize [:message!]

  def perform
    return unless message.outgoing? && !message.private? && message.inbox.web_widget?

    devices = SdkPushDevice.where(contact_inbox_id: message.conversation.contact_inbox_id, contact_id: message.conversation.contact_id,
                                  invalidated_at: nil)
    devices.find_each do |device|
      delivery = device.sdk_push_deliveries.create_or_find_by!(message: message)
      SdkPush::DeliveryJob.perform_later(delivery.id) if delivery.status == 'pending'
    end
  end
end
