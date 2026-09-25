class Channels::Whatsapp::TemplatesSyncJob < ApplicationJob
  queue_as :within_10_minutes

  def perform(whatsapp_channel)
    whatsapp_channel.sync_templates
  end
end
