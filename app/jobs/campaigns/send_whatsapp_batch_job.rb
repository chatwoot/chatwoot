class Campaigns::SendWhatsappBatchJob < ApplicationJob
  queue_as :low

  LOCK_BASE = 1_597_000_000_000

  def perform(campaign, cursor = 0)
    ApplicationRecord.connection_pool.with_connection do |connection|
      lock_id = LOCK_BASE + campaign.id
      next unless connection.select_value("SELECT pg_try_advisory_lock(#{lock_id})")

      begin
        send_batch(campaign.reload, cursor)
      ensure
        connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
      end
    end
  end

  private

  def send_batch(campaign, cursor)
    return if campaign.completed?

    next_cursor = Whatsapp::OneoffCampaignService.new(campaign: campaign).perform_batch(cursor)
    if next_cursor
      self.class.perform_later(campaign, next_cursor)
    else
      campaign.with_lock { campaign.completed! unless campaign.completed? }
    end
  end
end
