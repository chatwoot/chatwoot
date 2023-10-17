class Webhooks::FacebookDeliveryJob < MutexApplicationJob
  queue_as :default

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)
    Integrations::Facebook::DeliveryStatus.new(params: response).perform
  end
end
