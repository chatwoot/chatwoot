class Webhooks::FacebookDeliveryJob < ApplicationJob
  queue_as :low

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)
    Integrations::Facebook::DeliveryStatus.new(params: response).perform
  end
end
