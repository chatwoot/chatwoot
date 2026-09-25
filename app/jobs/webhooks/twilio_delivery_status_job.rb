class Webhooks::TwilioDeliveryStatusJob < ApplicationJob
  queue_as :within_10_minutes

  def perform(params = {})
    ::Twilio::DeliveryStatusService.new(params: params).perform
  end
end
