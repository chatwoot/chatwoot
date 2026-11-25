# How many history import batches may run at once across the whole instance, whatever the
# number of Sidekiq processes and threads.
#
# One pairing fans its dump out as a job per chat per frame, and with nothing holding them
# back 154 ran at once on a production instance: every host saturated and the web process
# answered 503 to live webhooks. Queue priority did not help, because once the imports held
# the threads and the CPU, a live job first in line still waited for the processor.
#
# It sits beside the chat lock (see Locks) and is taken before it: a batch whose chat is busy
# gives its slot back on the way out instead of holding the cap while it waits.
module Whatsapp::Session::Inbound::ImportSlots
  # Raised when every slot is taken. The job files itself for later rather than retrying, so
  # waiting for a slot spends no retry budget.
  class Full < StandardError; end

  DEFAULT_CONCURRENCY = 4
  KEY = 'WHATSAPP::HISTORY_IMPORT_SLOTS'.freeze
  # A slot is a lease rather than a counter, because a worker killed mid-import never runs
  # its `ensure`: a counter would keep that slot forever, and a few kills would end history
  # import on the instance. The lease is the chat lock's, which is already how long a batch
  # is allowed to run.
  LEASE = Whatsapp::Session::Inbound::Locks::IMPORT_CHAT_LOCK_TTL
  # Taking a slot is a read and a write that must see the same set. Under contention the
  # optimistic transaction loses to another worker; losing a few times in a row is read as
  # no slot, and the job simply comes back later.
  ATTEMPTS = 5
  # Where a batch that found every slot taken waits. No Sidekiq process reads it, so nothing
  # in it runs until somebody moves it out: whoever gives a slot back, a batch that has just
  # joined it and finds a slot free, and the minute sweep for a slot nobody gave back.
  #
  # It replaced a fixed delay of 15 to 30 seconds, which left a freed slot idle until one of
  # the delayed batches happened to come back: at a cap of 1, twenty batches of 0.7 s took
  # 380 s. Sidekiq's scheduled poller runs every few seconds on its own, so no shorter delay
  # could have closed the gap either.
  WAITING_QUEUE = 'history_import_waiting'.freeze

  module_function

  def with_slot(limit: concurrency)
    token = claim(limit)
    raise Full, "all #{limit} history import slots are taken" unless token

    begin
      yield
    ensure
      Redis::Alfred.with { |conn| conn.zrem(KEY, token) }
    end
  end

  # A positive whole number, or the default. Zero, a negative or a garbled value would
  # otherwise park every batch forever in silence, which is worse than the default cap.
  def concurrency
    value = Integer(ENV.fetch('HISTORY_IMPORT_MAX_CONCURRENCY', ''), exception: false)
    value&.positive? ? value : DEFAULT_CONCURRENCY
  end

  # Moves the oldest waiting batches, as many as there are free slots, to the head of the
  # queue they run from, so they are the next thing fetched there. Sidekiq pushes on the left
  # and fetches from the right: the block is taken off the right of the waiting queue and
  # pushed onto the right of the other in the same order, oldest outermost. One script, so a
  # batch is in one list or the other and never in neither.
  WAKE = <<~LUA.freeze
    local count = tonumber(ARGV[1])
    if count <= 0 then return 0 end
    local batches = redis.call('LRANGE', KEYS[1], -count, -1)
    if #batches == 0 then return 0 end
    redis.call('LTRIM', KEYS[1], 0, -(#batches + 1))
    redis.call('RPUSH', KEYS[2], unpack(batches))
    return #batches
  LUA

  # Says how many it woke. Two callers can see the same free slot and both wake a batch; the
  # one that loses the claim goes back to waiting, which costs a job and not a slot.
  def top_up(into:, limit: concurrency, waiting: "queue:#{WAITING_QUEUE}")
    free = limit - taken
    return 0 unless free.positive?

    Sidekiq.redis { |conn| conn.call('EVAL', WAKE, 2, waiting, "queue:#{into}", free) }
  end

  def taken
    Redis::Alfred.with { |conn| conn.zcount(KEY, Time.now.to_f, '+inf') }
  end

  # The slots are a sorted set of lease tokens scored by expiry, so a lease its holder never
  # gave back stops counting on its own. WATCH makes the count and the add one decision: a
  # worker that took a slot in between aborts this transaction instead of both taking the
  # last one.
  def claim(limit)
    token = SecureRandom.uuid
    ATTEMPTS.times do
      outcome = Redis::Alfred.with do |conn|
        conn.watch(KEY) do
          now = Time.now.to_f
          next conn.unwatch && :full if conn.zcount(KEY, now, '+inf') >= limit

          conn.multi do |transaction|
            transaction.zremrangebyscore(KEY, '-inf', now)
            transaction.zadd(KEY, now + LEASE.to_i, token)
            transaction.expire(KEY, LEASE.to_i)
          end
        end
      end
      return nil if outcome == :full
      return token if outcome
    end
    nil
  end
end
