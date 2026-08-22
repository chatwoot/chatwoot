class Webhooks::TwilioDeliveryStatusJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    params = params.with_indifferent_access if params.respond_to?(:with_indifferent_access)
    ::Twilio::DeliveryStatusService.new(params: params).perform
  end
end
