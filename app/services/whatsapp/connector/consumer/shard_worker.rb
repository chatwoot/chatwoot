# Owns one event shard: reads it, dispatches what it reads, acknowledges what it
# handled.
#
# The loop is deliberately single threaded and synchronous. Anything heavy that does
# not depend on ordering (downloading media, fetching an avatar) is already a job by
# the time it gets here, so the thread only ever does bookkeeping and database writes.
class Whatsapp::Connector::Consumer::ShardWorker
  Consumer = Whatsapp::Connector::Consumer

  # Pending entries are taken with no idle time at all. The shard lease is what
  # guarantees a single reader, so anything still pending here was left by an owner that
  # is already gone. Waiting one out would let `read_new` run ahead of it, advance the
  # session cursor past it, and then drop it as stale the moment it became claimable.
  CLAIM_IDLE_MS = 0
  BLOCK_MS = 5_000
  BATCH = 10

  # Waits between attempts at one entry. A handler that failed on a deadlock or on a
  # connection reset gets a few more passes before the event is parked.
  RETRY_WAITS = [1, 5, 30].freeze
  # Contention on the chat lock is expected rather than exceptional: a group roster sync
  # started from Sidekiq holds it for as long as GROUP_SYNC_LOCK_TTL, and the events of
  # that group have to wait it out. Waiting stalls the shard, which is what ordering
  # costs: skipping ahead would hand the session its events out of order, and there is
  # no way to put one back.
  #
  # The longest holder is a history import, whose lease is IMPORT_CHAT_LOCK_TTL: an import
  # yields to a waiter before it starts, but a worker killed mid-import leaves the lease to
  # run out on its own. So the ladder has to outlast that lease, or a live message that
  # lands on the chat right then is parked with the lock about to come free.
  BUSY_WAITS = [5, 15, 30, 60, 60, 60, 60, 60].freeze
  PAUSE_SLICE = 0.5
  # How long an event about a message not stored yet waits before its first retry.
  DEFERRED_WAIT = 30.seconds
  # How long the shard waits out an outage before it tries its backlog again.
  STALL_WAIT = 30

  # Failures that say nothing about the event: the database is gone, its pool is
  # exhausted, Redis went away. Dead-lettering one of these would empty a stream into a
  # capped list during a failover and record it as processed, so they leave the entry
  # pending instead and the shard waits. Matched by name through the ancestors, because a
  # constant holding another file's class survives a reload and stops matching.
  #
  # Named at the branch rather than the leaf: a connection dropped mid-query raises
  # ConnectionFailed, which hangs off QueryAborted and not off ConnectionNotEstablished,
  # so a list of leaves missed the most ordinary shape a failover takes.
  #
  # Enqueueing a job is Redis too, and not through the same client: Sidekiq talks
  # redis-client behind a connection pool, so its outages arrive as RedisClient errors or
  # as a pool that ran out, and match nothing the gem this worker uses raises. A handler
  # that only failed to enqueue its own follow-up work is the most ordinary shape of all.
  INFRASTRUCTURE_ERRORS = %w[
    ActiveRecord::ConnectionNotEstablished ActiveRecord::QueryAborted
    PG::ConnectionBad PG::UnableToSend
    Redis::BaseConnectionError Redis::TimeoutError
    RedisClient::ConnectionError ConnectionPool::TimeoutError
  ].freeze

  attr_reader :shard, :consumer_id, :lease

  def initialize(shard, consumer_id, lease)
    @shard = shard
    @consumer_id = consumer_id
    @lease = lease
    @stopped = false
  end

  def run
    poll until stopped?
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP CONNECTOR] shard #{shard} died: #{e.class}: #{e.message}")
    ChatwootExceptionTracker.new(e).capture_exception
  ensure
    @redis&.close
  end

  def stop
    @stopped = true
  end

  def stopped?
    @stopped
  end

  # One pass: everything a previous owner left behind, then what is new. The backlog is
  # drained first and in full, because an event read out of that order is an event whose
  # session sees its own history rearranged. Returns the number of entries processed,
  # which is what makes the loop testable without threads.
  def poll
    ensure_group
    @stalled = false
    handled = claim_orphans + read_new
    # Nothing to spin on: the entries are still pending and the next pass finds them.
    pause(STALL_WAIT) if @stalled
    handled
  end

  private

  def stream = Consumer.shard_key(shard)

  # Resolved when called: a constant captured at load time keeps the namespace from
  # before the last reload, whose autoloaded children have been removed from it.
  def model = Whatsapp::Session::Model

  def redis
    @redis ||= Redis.new(Redis::Config.app.merge(timeout: (BLOCK_MS / 1000) + 5))
  end

  # Created at 0 rather than at $: whatever the connector published while no consumer
  # was running is still on the stream, and losing it would lose messages. Replays are
  # harmless, because the cursor already decides what was processed.
  def ensure_group
    redis.xgroup(:create, stream, Consumer::GROUP, '0', mkstream: true)
  rescue Redis::CommandError => e
    # BUSYGROUP: another consumer created it first, which is the normal case.
    raise unless e.message.include?('BUSYGROUP')
  end

  # Entries a previous owner read and never acknowledged, because it died or was told to
  # stop holding them. Walked to the end of the pending list rather than one batch at a
  # time: a backlog longer than BATCH would otherwise be overtaken by `read_new`.
  def claim_orphans
    position = '0-0'
    processed = 0
    loop do
      claimed = redis.xautoclaim(stream, Consumer::GROUP, consumer_id, CLAIM_IDLE_MS, position, count: BATCH)
      processed += process(claimed['entries'])
      position = claimed['next']
      break if position.blank? || position == '0-0' || stopped? || @stalled
    end
    processed
  rescue Redis::CommandError => e
    raise unless e.message.include?('NOGROUP')

    ensure_group
    0
  end

  def read_new
    response = redis.xreadgroup(Consumer::GROUP, consumer_id, stream, '>', count: BATCH, block: BLOCK_MS)
    process(response&.dig(stream) || {})
  end

  def process(entries)
    handled = 0
    entries.to_a.each do |entry_id, fields|
      # A worker whose process is going away leaves the rest of the batch alone: the
      # entries stay pending and whoever takes the shard next drains them before reading
      # anything new. Acknowledging them unprocessed here would drop the events instead.
      break if stopped? || @stalled

      handled += 1 if handle(entry_id, fields)
    end
    handled
  end

  def handle(entry_id, fields)
    outcome = deliver(entry_id, fields)
    redis.xack(stream, Consumer::GROUP, entry_id) unless outcome == :abandoned
    outcome == :handled
  end

  # Runs the entry, retrying what a second attempt could fix. Answers :handled, :parked
  # (dead-lettered) or :abandoned (left pending, because this worker is stopping).
  #
  # Each attempt is wrapped in the executor on its own, so the waits between them do not
  # hold an ActiveRecord connection: this is a long-lived thread outside the request
  # cycle, and a connection checked out here is not returned until the wrap closes.
  def deliver(entry_id, fields)
    attempt = 0
    begin
      attempt += 1
      return :abandoned unless owned?

      Rails.application.executor.wrap { dispatch(model::Event.from_frame(decode(fields))) }
      :handled
    rescue Whatsapp::Session::Errors::InvalidEvent, Whatsapp::Session::Errors::InvalidPayload, JSON::ParserError => e
      # A frame this build cannot read does not become readable by being read again.
      # InvalidPayload belongs here with InvalidEvent: every raiser of it is a shape check
      # on the payload itself, and the webhook job, which is the same contract on the HTTP
      # side, already drops the two together. Without it a malformed nested field stalls every
      # session on the shard for the whole retry ladder before being parked anyway.
      dead_letter(entry_id, fields, e)
      :parked
    rescue Whatsapp::Session::Inbound::Locks::Busy => e
      outcome = next_outcome(entry_id, fields, e, BUSY_WAITS[attempt - 1])
      retry if outcome == :retry

      outcome
    rescue StandardError => e
      outcome = next_outcome(entry_id, fields, e, RETRY_WAITS[attempt - 1])
      retry if outcome == :retry

      outcome
    end
  end

  def next_outcome(entry_id, fields, error, wait)
    return :abandoned if stopped?

    if wait.nil?
      return stall(error) if infrastructure?(error)

      dead_letter(entry_id, fields, error)
      return :parked
    end

    Rails.logger.warn("[WHATSAPP CONNECTOR] shard #{shard} retrying in #{wait}s: #{error.class}: #{error.message}")
    pause(wait)
    stopped? ? :abandoned : :retry
  end

  def stall(error)
    Rails.logger.warn("[WHATSAPP CONNECTOR] shard #{shard} waiting: #{error.class}: #{error.message}")
    @stalled = true
    :abandoned
  end

  def infrastructure?(error)
    error.class.ancestors.any? { |klass| INFRASTRUCTURE_ERRORS.include?(klass.name) }
  end

  # Sliced so that a shutdown does not have to wait out the whole backoff.
  def pause(seconds)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    sleep(PAUSE_SLICE) while !stopped? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
  end

  # Every stream field is a string; the payload is the only one carrying JSON.
  def decode(fields)
    fields.merge('payload' => JSON.parse(fields['payload'].presence || '{}'))
  end

  def dispatch(event)
    channel = channel_for(event.sid)
    return orphaned(event) if channel.nil?
    return unless cursor.behind?(event)

    outcome = Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)
    # Its target may be a history message still queued for import, which the stream's
    # order no longer covers: tried again off the shard rather than waited on here.
    Whatsapp::Session::DeferredEventJob.set(wait: DEFERRED_WAIT).perform_later(channel, event.to_frame) if outcome == :deferred
    mark_processed(event)
  end

  # A session no inbox holds any more. Nearly everything about it is dropped, but a
  # teardown's failure arrives here by construction: the inbox that asked for it has been
  # destroyed or moved to another provider by the time the connector answers. The cursor
  # guards it as it guards an inbox's events, or every replay would schedule another one.
  def orphaned(event)
    return if event.sid.blank? || event.type != 'command.failed'
    return unless cursor.behind?(event)

    Whatsapp::Session::TeardownRetry.consider(event)
    mark_processed(event)
  end

  # The lease can lapse while this thread is inside an entry: one long stall, or a Redis
  # that went away for half a minute. A peer takes the shard the moment it does, claims
  # what is pending, and starts reading alongside this thread. The supervisor notices on
  # its next tick, but a tick is seconds away and a dispatch commits sooner than that, so
  # the check belongs here, before every attempt, and the shard is left alone afterwards.
  #
  # The entry stays pending: whoever holds the shard now is the one that should handle it.
  def owned?
    return true if lease.fresh?(shard)

    Rails.logger.warn("[WHATSAPP CONNECTOR] shard #{shard} is no longer ours to read; stopping")
    stop
    false
  end

  def channel_for(session_id)
    return if session_id.blank?

    # Narrowed to the provider as well as the id: the session-id index is partial on the
    # session providers, so without this Postgres cannot use it and reads the table for
    # every event, and a colliding id could resolve another provider's inbox.
    channel = Channel::Whatsapp.where(provider: 'native')
                               .where("provider_config->>'session_id' = ?", session_id).first
    Rails.logger.warn("[WHATSAPP CONNECTOR] no inbox for session #{session_id}") if channel.nil?
    channel
  end

  def cursor
    @cursor ||= Whatsapp::Connector::Consumer::SessionCursor.new(redis)
  end

  # A cursor that cannot be written must not undo the dispatch that just succeeded:
  # raising here would send the entry back through the retry ladder and run the handler a
  # second time for certain, where losing the cursor only risks a replay in the case where
  # the entry is redelivered at all.
  def mark_processed(event)
    cursor.advance(event)
  rescue Redis::BaseError => e
    Rails.logger.warn("[WHATSAPP CONNECTOR] cursor for session #{event.sid} not written: #{e.message}")
  end

  # Nothing that gets here is worth retrying forever: a payload this build cannot read
  # will not become readable, and blocking the shard on it would stop every session that
  # shares it.
  #
  # A record, not a queue. Putting one of these back on the stream would not work and
  # should not: the session has moved on, its cursor is past this event, and handing a
  # handler an event from before the state it already wrote is what the ordering in this
  # whole design exists to prevent. What the list is for is seeing what could not be read
  # and fixing the cause, so it carries the session and the position the event held.
  def dead_letter(entry_id, fields, error)
    Rails.logger.error("[WHATSAPP CONNECTOR] shard #{shard} dropped #{entry_id}: #{error.class}: #{error.message}")
    ChatwootExceptionTracker.new(error).capture_exception
    redis.lpush(Consumer.dlq_key, { 'shard' => shard, 'entry_id' => entry_id, 'sid' => fields['sid'],
                                    'cursor' => "#{fields['epoch']}:#{fields['seq']}", 'fields' => fields,
                                    'error' => "#{error.class}: #{error.message}" }.to_json)
    redis.ltrim(Consumer.dlq_key, 0, 999)
  end
end
