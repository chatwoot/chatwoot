class Webhooks::FacebookDeliveryJob < ApplicationJob
  queue_as :within_10_minutes

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)
    Integrations::Facebook::DeliveryStatus.new(params: response).perform
  end
end
