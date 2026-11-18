# Sends a WhatsApp number's call hours to Meta, one sync per number at a time. A job queued while
# another is sending waits for it, then sends whatever is current if the channel is still pending.
class Whatsapp::SyncCallHoursJob < MutexApplicationJob
  queue_as :default
  retry_on_lock_conflict wait: 2.seconds, attempts: 10

  # Outlasts reading and updating the settings at Meta, whose connect, send, and read steps are each
  # bounded by SETTINGS_REQUEST_TIMEOUT_SECONDS
  LOCK_TIMEOUT = 2.minutes

  def perform(channel)
    with_lock(format(Redis::Alfred::WHATSAPP_CALL_HOURS_SYNC_MUTEX, channel_id: channel.id), LOCK_TIMEOUT) do
      channel.reload
      next unless channel.call_hours_sync_status == 'pending'

      Whatsapp::CallHoursSyncService.new(channel: channel).perform
    end
  end
end
