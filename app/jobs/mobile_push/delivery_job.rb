class MobilePush::DeliveryJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound
  retry_on CustomExceptions::MobilePushError, wait: :polynomially_longer, attempts: 5 do |job, error|
    MobilePushDelivery.find_by(id: job.arguments.first)&.update!(status: 'rejected', reason: error.message)
  end

  def perform(delivery_id)
    delivery = MobilePushDelivery.find(delivery_id)
    delivery.with_lock do
      return unless delivery.status == 'pending'

      device = delivery.mobile_push_device
      unless device.invalidated_at.nil? && device.contact_inbox.contact_id == device.contact_id &&
             (!delivery.message || delivery.message.conversation.contact_id == device.contact_id)
        delivery.update!(status: 'rejected', reason: 'CustomerSessionChanged')
        return
      end
      MobilePush::ApnsService.new(delivery: delivery).perform
    end
  end
end
