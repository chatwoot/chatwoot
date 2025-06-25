class Webhooks::FacebookEventsJob < ApplicationJob
  queue_as :default

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)
    ::Integrations::Facebook::MessageCreator.new(response).perform
  end
end
