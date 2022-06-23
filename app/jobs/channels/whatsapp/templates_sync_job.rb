class Channels::Whatsapp::TemplatesSyncJob < ApplicationJob
  queue_as :low

  def perform(whatsapp_channel)
    whatsapp_channel.sync_templates
  end
end
