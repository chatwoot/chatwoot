class Channels::Whatsapp::HealthSyncJob < ApplicationJob
  queue_as :low

  def perform(whatsapp_channel)
    Whatsapp::HealthService.new(whatsapp_channel).sync_health_status!
  rescue Whatsapp::HealthService::ApiError, ArgumentError
    nil
  end
end
