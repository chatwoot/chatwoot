class Shopee::SyncJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Channel::Shopee.ids.each do |channel_id|
      Shopee::SyncVouchersJob.perform_later(channel_id: channel_id)
      Shopee::SyncProductsJob.perform_later(channel_id: channel_id)
    end
  end

end
