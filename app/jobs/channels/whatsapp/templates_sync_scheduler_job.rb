class Channels::Whatsapp::TemplatesSyncSchedulerJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Whatsapp.where('message_templates_last_updated <= ? OR message_templates_last_updated IS NULL',
                            15.minutes.ago).find_in_batches do |channels_batch|
      channels_batch.each do |channel|
        Channels::Whatsapp::TemplatesSyncJob.perform_later(channel)
      end
    end
  end
end
