class Whatsapp::SyncCallHoursJob < MutexApplicationJob
  queue_as :default
  retry_on_lock_conflict wait: 2.seconds, attempts: 10

  LOCK_TIMEOUT = 2.minutes

  def perform(channel)
    with_lock(format(Redis::Alfred::WHATSAPP_CALL_HOURS_SYNC_MUTEX, channel_id: channel.id), LOCK_TIMEOUT) do
      channel.reload
      next unless channel.call_hours_sync_status == 'pending'

      Whatsapp::CallHoursSyncService.new(channel: channel).perform
    end
  end
end
