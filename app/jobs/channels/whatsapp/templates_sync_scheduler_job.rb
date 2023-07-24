class Channels::Whatsapp::TemplatesSyncSchedulerJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Whatsapp.where('message_templates_last_updated <= ? OR message_templates_last_updated IS NULL',
                            3.hours.ago).limit(Limits::BULK_EXTERNAL_HTTP_CALLS_LIMIT).all.each do |channel|
      Channels::Whatsapp::TemplatesSyncJob.perform_later(channel)
    end
  end
end
