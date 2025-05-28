class Webhooks::TwilioDeliveryStatusJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    ::Twilio::DeliveryStatusService.new(params: params).perform
  end
end
