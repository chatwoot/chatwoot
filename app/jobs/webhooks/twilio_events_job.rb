class Webhooks::TwilioEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    # Process the Twilio webhook event in the background
    ::Twilio::IncomingMessageService.new(params: params).perform
  end
end
