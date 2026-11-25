# One slice of history, filed off the thread that read it.
#
# The session layer's twin of Whatsapp::Baileys::HistoryImportJob, and it holds itself back
# the same way: an import slot before the chat lock, a batch that finds every slot taken
# waits in the queue nobody reads until a slot is given back, and a chat busy with live
# traffic is waited out on the lock's own budget. Inline on the connector's consumer, a
# pairing dump held the shard for as long as the whole archive took to write, and every
# live event of every session behind it waited that long.
#
# The boundary is read before the job is queued and handed in, because slices run in
# parallel: one reading it for itself would measure against what the slices that went
# first had already written.
class Whatsapp::Session::HistoryImportJob < ApplicationJob
  queue_as :low

  # The same budget as the Baileys job, for the same reason: what a slice waits out on the
  # chat lock is mostly the slices of the same chat queued ahead of it.
  BUSY_ATTEMPTS = 40
  retry_on Whatsapp::Session::Inbound::Locks::Busy, wait: 30.seconds, attempts: BUSY_ATTEMPTS do |job, error|
    inbox = job.arguments.first
    job.class.finished(inbox, job.job_id) if inbox.is_a?(Inbox)
    raise error
  end

  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.info("Skipping #{job.class} because of ActiveJob::DeserializationError (#{error.message})")
    Whatsapp::Session::Inbound::ImportSlots.top_up(into: job.class.queue_name)
  end

  # Who the slice was read from, which the job reads back before writing: while it waited
  # the inbox may have moved to another provider, or been pointed at another instance or
  # session of the same one, and a pile from the previous account filed here would be
  # somebody else's conversations. The dispatcher asks the same question of an event;
  # this is the same event arriving late. The number is part of it because a native inbox
  # keeps its session id when it is re-pointed at another number and paired again.
  def self.identity(channel)
    [channel.provider, Whatsapp::Session::Registry.instance_fingerprint(channel) || channel.provider_config&.dig('session_id'),
     channel.phone_number.to_s]
  end

  # Which slices of an inbox are still queued, so an event about a message one of them
  # carries knows to keep waiting (see DeferredEventJob). A slice can wait for a slot for as
  # long as the dump ahead of it takes, which no fixed retry ladder outlasts. A job that
  # never finishes is forgotten after PENDING_TTL rather than holding the events forever.
  PENDING_TTL = 24.hours

  def self.queued(inbox, job_id)
    Redis::Alfred.with do |conn|
      conn.zadd(pending_key(inbox), Time.now.to_f, job_id)
      conn.expire(pending_key(inbox), PENDING_TTL.to_i)
    end
  end

  def self.pending?(inbox)
    Redis::Alfred.with do |conn|
      conn.zremrangebyscore(pending_key(inbox), '-inf', Time.now.to_f - PENDING_TTL.to_i)
      conn.zcard(pending_key(inbox)).positive?
    end
  end

  def self.finished(inbox, job_id)
    Redis::Alfred.with { |conn| conn.zrem(pending_key(inbox), job_id) }
  end

  def self.pending_key(inbox) = "WHATSAPP::HISTORY_IMPORTS_PENDING::#{inbox.id}"

  # `messages` are the slice as the contract puts it on the wire. Everything after
  # `requested` says how to file it rather than what is in it, and is collected rather than
  # listed for the reason the Baileys job gives: a job's arguments outlive the deploy that
  # queued them.
  def perform(inbox, messages, watermark, requested, **filing)
    self.queue_name = self.class.queue_name
    channel = inbox&.channel
    # Dropped without taking a slot, so it gives none back: the batch behind it is woken
    # here or it waits for the sweep.
    return skip(inbox) unless same_account?(channel, filing[:identity])

    held = false
    slots.with_slot do
      held = true
      import(channel, messages, watermark, requested, filing)
    end
    self.class.finished(inbox, job_id)
  rescue Whatsapp::Session::Inbound::ImportSlots::Full
    retry_job(queue: slots::WAITING_QUEUE)
    slots.top_up(into: self.class.queue_name)
  # A slice that failed stops holding the inbox's deferred events: Sidekiq retries it for
  # weeks, and they would wait on it for the whole PENDING_TTL. Only the chat lock sends it
  # back to wait as the same job, so only that keeps it pending, until its last attempt
  # (the block on retry_on above).
  rescue StandardError => e
    let_go(inbox, e)
    raise
  ensure
    slots.top_up(into: self.class.queue_name) if held
  end

  private

  def slots = Whatsapp::Session::Inbound::ImportSlots

  def let_go(inbox, error)
    self.class.finished(inbox, job_id) if inbox && !error.is_a?(Whatsapp::Session::Inbound::Locks::Busy)
  end

  def skip(inbox)
    self.class.finished(inbox, job_id) if inbox
    slots.top_up(into: queue_name)
  end

  def same_account?(channel, identity)
    return false unless channel.is_a?(Channel::Whatsapp) && Whatsapp::Session::Registry.session_provider?(channel.provider)

    identity.nil? || Array(identity) == self.class.identity(channel)
  end

  def import(channel, messages, watermark, requested, filing)
    Whatsapp::Session::Inbound::HistoryImporter.new(
      channel: channel,
      messages: Array(messages).map { |raw| Whatsapp::Session::Model::InboundMessage.from_h(raw) },
      requested: requested, watermark: watermark,
      announce: filing.fetch(:announce, false), group_name: filing[:group_name],
      exhausted: filing[:exhausted] && Whatsapp::Session::Model::Address.from_h(filing[:exhausted])
    ).perform
  end
end
