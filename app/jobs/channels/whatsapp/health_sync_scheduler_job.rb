class Channels::Whatsapp::HealthSyncSchedulerJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Whatsapp.joins(:account)
                     .merge(Account.active)
                     .where(provider: 'whatsapp_cloud')
                     .where('phone_number_health_checked_at <= ? OR phone_number_health_checked_at IS NULL', 6.hours.ago)
                     .order(Arel.sql('phone_number_health_checked_at IS NULL DESC, phone_number_health_checked_at ASC'))
                     .limit(Limits::BULK_EXTERNAL_HTTP_CALLS_LIMIT)
                     .each do |channel|
      Channels::Whatsapp::HealthSyncJob.perform_later(channel)
    end
  end
end
