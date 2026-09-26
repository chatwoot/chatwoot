class SdkPush::DeliveryJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound
  retry_on CustomExceptions::SdkPushError, wait: :polynomially_longer, attempts: 5 do |job, error|
    SdkPushDelivery.find_by(id: job.arguments.first)&.update!(status: 'rejected', reason: error.message)
  end

  def perform(delivery_id)
    delivery = SdkPushDelivery.find(delivery_id)
    delivery.with_lock do
      return unless delivery.status == 'pending'

      device = delivery.sdk_push_device
      unless current_customer_session?(device, delivery.message)
        delivery.update!(status: 'rejected', reason: 'CustomerSessionChanged')
        return
      end
      unless device.push_enabled?
        delivery.update!(status: 'rejected', reason: 'PushNotificationsDisabled')
        return
      end
      service = device.platform == 'ios' ? SdkPush::ApnsService : SdkPush::FcmService
      service.new(delivery: delivery).perform
    end
  end

  private

  def current_customer_session?(device, message)
    device.invalidated_at.nil? && device.contact_inbox.contact_id == device.contact_id &&
      (!message || message.conversation.contact_id == device.contact_id)
  end
end
