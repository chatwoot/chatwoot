# How far a session has been processed, as an `epoch:seq` position.
#
# It exists for redelivery: a consumer that takes a shard over mid-flight re-reads
# entries the previous owner had already handled, and the ones carrying no message are
# not covered by message-level deduplication. Delivery is at least once either way, so
# this is an optimization on top of the handlers' own idempotency, not a guarantee.
#
# It only ever moves forwards. A shard count change is the one time two workers can hold
# the same session at once, and a plain SET would let the one reading the older stream
# put the cursor back, after which events already processed would run a second time.
class Whatsapp::Connector::Consumer::SessionCursor
  Consumer = Whatsapp::Connector::Consumer

  # How long a cursor outlives the session it belongs to. It only has to outlast what a
  # stream can redeliver, which is bounded by its MAXLEN; the TTL is there so a deleted
  # inbox does not leave a key behind forever.
  TTL = 30.days.to_i

  # Compared as two numbers, because "10:1" sorts before "9:1" as a string.
  ADVANCE = <<~LUA.freeze
    local current = redis.call('get', KEYS[1])
    local epoch, seq = tonumber(ARGV[1]), tonumber(ARGV[2])
    if current then
      local held_epoch, held_seq = string.match(current, '(%d+):(%d+)')
      held_epoch, held_seq = tonumber(held_epoch), tonumber(held_seq)
      if held_epoch and (held_epoch > epoch or (held_epoch == epoch and held_seq >= seq)) then
        return 0
      end
    end
    redis.call('set', KEYS[1], epoch .. ':' .. seq, 'EX', ARGV[3])
    return 1
  LUA

  def initialize(redis)
    @redis = redis
  end

  # A refusal is said out loud. It is right for a redelivery and wrong for a session whose
  # counter started over, and from the consumer the two look the same: this line is what
  # tells them apart, since nothing in the inbox changes either way (fazer-ai/chatwoot#852).
  def behind?(event)
    held = position(event.sid)
    return true if held.blank? || event.newer_than?(held.split(':').map(&:to_i))

    Rails.logger.warn(
      "[WHATSAPP CONNECTOR] #{event.type} for session #{event.sid} at #{event.cursor.join(':')} dropped: " \
      "the session was already processed up to #{held}"
    )
    false
  end

  def position(session_id)
    @redis.get(key(session_id))
  end

  def advance(event)
    epoch, seq = event.cursor
    @redis.eval(ADVANCE, keys: [key(event.sid)], argv: [epoch, seq, TTL])
  end

  private

  def key(session_id)
    Consumer.cursor_key(session_id)
  end
end
