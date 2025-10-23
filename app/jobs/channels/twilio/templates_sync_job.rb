class Channels::Twilio::TemplatesSyncJob < ApplicationJob
  queue_as :low

  def perform(twilio_channel)
    Twilio::TemplateSyncService.new(channel: twilio_channel).call
  end
end
