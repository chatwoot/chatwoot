class Channels::Twilio::WebhookSetupJob < ApplicationJob
  queue_as :within_10_minutes

  def perform(twilio_channel)
    ::Twilio::WebhookSetupService.new(channel: twilio_channel).perform
  end
end
