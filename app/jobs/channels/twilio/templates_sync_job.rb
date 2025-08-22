class Channels::Twilio::TemplatesSyncJob < ApplicationJob
  queue_as :low

  def perform(twilio_channel)
    twilio_channel.sync_templates
  end
end
