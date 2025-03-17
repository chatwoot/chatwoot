class Webhooks::TwilioDeliveryStatusJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    # Process the Twilio delivery status webhook event in the background
    ::Twilio::DeliveryStatusService.new(params: params).perform
  end
end
