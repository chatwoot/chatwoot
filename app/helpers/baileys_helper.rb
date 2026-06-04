module BaileysHelper
  CHANNEL_LOCK_ON_OUTGOING_MESSAGE_KEY = 'BAILEYS::CHANNEL_LOCK_ON_OUTGOING_MESSAGE::%<channel_id>s'.freeze
  CHANNEL_LOCK_ON_OUTGOING_MESSAGE_TIMEOUT = 60.seconds

  def baileys_extract_message_timestamp(timestamp)
    # NOTE: Timestamp might be in this format {"low"=>1748003165, "high"=>0, "unsigned"=>true}
    if timestamp.is_a?(Hash) && timestamp.key?('low')
      low = timestamp['low'].to_i
      high = timestamp.fetch('high', 0).to_i
      return (high << 32) | low
    end

    # NOTE: Timestamp might be a string or a number
    timestamp.to_i
  end

  def with_baileys_channel_lock_on_outgoing_message(channel_id, timeout: CHANNEL_LOCK_ON_OUTGOING_MESSAGE_TIMEOUT)
    raise ArgumentError, 'A block is required for with_baileys_channel_lock_on_outgoing_message' unless block_given?

    start_time = Time.now.to_i
    lock_acquired = false

    # NOTE: On timeout, we log a warning and proceed with the block execution.
    # The re-check inside the contact lock handles potential duplicates.
    while (Time.now.to_i - start_time) < timeout
      if baileys_lock_channel_on_outgoing_message(channel_id, timeout)
        lock_acquired = true
        break
      end

      sleep(0.1)
    end

    Rails.logger.warn "Baileys channel lock timeout for channel #{channel_id} after #{timeout}s - proceeding anyway" unless lock_acquired

    yield
  ensure
    baileys_clear_channel_lock_on_outgoing_message(channel_id)
  end

  private

  def baileys_lock_channel_on_outgoing_message(channel_id, timeout)
    key = format(CHANNEL_LOCK_ON_OUTGOING_MESSAGE_KEY, channel_id: channel_id)
    Redis::Alfred.set(key, 1, nx: true, ex: timeout)
  end

  def baileys_clear_channel_lock_on_outgoing_message(channel_id)
    key = format(CHANNEL_LOCK_ON_OUTGOING_MESSAGE_KEY, channel_id: channel_id)
    Redis::Alfred.delete(key)
  end
end
