# Works through an inbox's history files, newest first, one download at a time.
#
# One of these per inbox at most: `kick` queues it only when none is queued or running,
# and it queues itself again while the inbox still has files waiting. So however large
# the dump, an inbox has a single download in flight for its history, and the low queue
# holds one entry for it, behind which the live media on the medium queue never waits.
#
# Each run takes a bounded batch and hands the queue back, so a dump of thousands of files
# does not hold a worker thread for the hours it takes.
class Whatsapp::Session::HistoryMediaJob < ApplicationJob
  queue_as :low

  BATCH = 20
  # A run also stops at this, so a batch of large files hands its thread and its slot back
  # well inside the slot's lease.
  BATCH_TIME = 1.minute
  # How long a run that found every history slot taken waits before trying again.
  SLOT_WAIT = 15.seconds
  # Only a backstop for a run that died without clearing it: a live run refreshes it.
  SCHEDULED_TTL = 1.hour
  # The provider could not be reached, or asked us to slow down. The files stay queued and
  # the drain comes back.
  UNAVAILABLE_WAIT = 2.minutes
  TRANSIENT = [Down::Error, Whatsapp::Session::Errors::ProviderUnavailable, Whatsapp::Session::Errors::RateLimited].freeze

  # `requeue` asks the drain to first collect the pending files the consent covers, for
  # when it has just grown (Whatsapp::Session::HistoryMedia.requeue). It is a flag of its
  # own and not an argument of the run: a drain already queued or running would otherwise
  # swallow the request, and the files the change just covered would never be queued.
  def self.kick(inbox, wait: nil, requeue: false)
    held = ActiveSupport::IsolatedExecutionState[HOLD]
    return held << inbox if held && !requeue

    # No expiry: a low queue that takes longer than the lease to reach the run must not
    # lose the request, since nothing else would ever queue the files it covers.
    Redis::Alfred.set(requeue_key(inbox), SecureRandom.uuid) if requeue
    return unless Redis::Alfred.set(scheduled_key(inbox), '1', nx: true, ex: SCHEDULED_TTL.to_i)

    begin
      set(wait: wait).perform_later(inbox)
    rescue StandardError
      # Nothing was queued, so nothing will clear the claim: the next file, or the minute
      # sweep (resume_stranded), has to find it free.
      Redis::Alfred.delete(scheduled_key(inbox))
      raise
    end
  end

  # A slice is written oldest first. A drain started while it is being written takes the
  # newest file written so far, so the import holds the kicks of its files until the slice
  # is in and kicks once (Inbound::HistoryImporter#perform).
  #
  # The end of a slice also collects the files already waiting in the inbox, at most once
  # per RESCAN_EVERY: a file is queued when it is written, and one written before this
  # existed, or queued when nothing could run it, would otherwise wait for a change of the
  # settings to be asked for.
  HOLD = :whatsapp_history_media_hold
  RESCAN_EVERY = 10.minutes

  def self.holding(inbox)
    previous = ActiveSupport::IsolatedExecutionState[HOLD]
    ActiveSupport::IsolatedExecutionState[HOLD] = held = []
    yield
  ensure
    ActiveSupport::IsolatedExecutionState[HOLD] = previous
    after_slice(inbox, held)
  end

  def self.after_slice(inbox, held)
    return unless Whatsapp::Session::HistoryMedia.enabled?(inbox.channel.provider_config)

    rescan = Redis::Alfred.set("WHATSAPP::HISTORY_MEDIA_RESCANNED::#{inbox.id}", '1', nx: true, ex: RESCAN_EVERY.to_i)
    kick(inbox, requeue: rescan.present?) if held.present? || rescan
  end

  def self.scheduled_key(inbox) = "WHATSAPP::HISTORY_MEDIA_SCHEDULED::#{inbox.id}"
  def self.requeue_key(inbox) = "WHATSAPP::HISTORY_MEDIA_REQUEUE::#{inbox.id}"

  # The scheduling claim says a run is queued and lapses if the queue sits on it too long;
  # the run claim says one is working, and is what keeps two drains of one inbox from
  # downloading the same head. A run that finds it taken leaves: the one working queues
  # its own continuation.
  RUN_TTL = BATCH_TIME + 5.minutes

  # Run by the minute sweep. A queue or a rescan request with no drain behind it is left by
  # a drain that could not be queued: the importer that tracked those files has finished,
  # and a retry of it skips the messages it already wrote, so nothing else would ever come
  # back for them. `kick` does nothing for an inbox whose drain is queued or running.
  #
  # The keys of an inbox that was deleted go here too: its jobs are discarded, so nothing
  # else would ever empty them.
  def self.resume_stranded
    ids = Redis::Alfred.with do |conn|
      %w[HISTORY_MEDIA HISTORY_MEDIA_REQUEUE].flat_map do |name|
        conn.scan_each(match: "WHATSAPP::#{name}::*").map { |key| key.split('::').last.to_i }
      end
    end.uniq
    inboxes = Inbox.where(id: ids).includes(:channel).to_a
    # An inbox with the fetch off keeps its queue for when it is turned back on, which
    # resumes it from the settings callback; waking it here would only spin a run a minute.
    inboxes.each { |inbox| kick(inbox) if Whatsapp::Session::HistoryMedia.enabled?(inbox.channel.provider_config) }
    (ids - inboxes.map(&:id)).each { |id| forget(Inbox.new(id: id)) }
  end

  def self.forget(inbox)
    keys = [Whatsapp::Session::HistoryMedia.queue_key(inbox), requeue_key(inbox), cursor_key(inbox), scheduled_key(inbox), run_key(inbox)]
    keys.each do |key|
      Redis::Alfred.delete(key)
    end
  end

  def perform(inbox)
    @inbox = inbox
    @run = SecureRandom.uuid
    return unless Redis::Alfred.set(self.class.run_key(inbox), @run, nx: true, ex: RUN_TTL.to_i)

    begin
      Redis::Alfred.set(self.class.scheduled_key(inbox), '1', ex: SCHEDULED_TTL.to_i)
      work
    ensure
      release
    end
  end

  def self.run_key(inbox) = "WHATSAPP::HISTORY_MEDIA_RUNNING::#{inbox.id}"
  def self.cursor_key(inbox) = "WHATSAPP::HISTORY_MEDIA_REQUEUE_CURSOR::#{inbox.id}"

  private

  attr_reader :inbox

  def work
    return finish unless enabled?

    history_media.with_slot(on_full: -> { again(SLOT_WAIT) }) do
      @deadline = BATCH_TIME.from_now
      rescan
      drain
    end
  end

  def history_media = Whatsapp::Session::HistoryMedia
  def queue_key = history_media.queue_key(inbox)

  # The request is cleared only once the collection went through, so a worker that stops
  # halfway leaves it for the next run, and only if it is still the one this run read: one
  # asked for while collecting is for files this pass may have missed.
  #
  # It shares the run's time budget, and one that runs out keeps its place in the cursor;
  # the drain then finds the budget spent and queues the next run, which picks it up there.
  def rescan
    request = Redis::Alfred.get(self.class.requeue_key(inbox))
    return if request.nil?

    from = history_media.requeue(inbox, from: resume_from(request), deadline: @deadline)
    return Redis::Alfred.set(self.class.cursor_key(inbox), "#{request}:#{from}") if from

    Redis::Alfred.delete(self.class.cursor_key(inbox))
    Redis::Alfred.delete_if_equals(self.class.requeue_key(inbox), request)
  end

  # The cursor belongs to the request that left it. A new request (the window widened
  # again mid-walk) starts from the newest message: the messages its wider window adds can
  # sit anywhere in the id order, above the cursor as well.
  def resume_from(request)
    owner, from = Redis::Alfred.get(self.class.cursor_key(inbox)).to_s.split(':')
    from.to_i if owner == request && from
  end

  # Read from the database, not from the channel loaded with the job: a batch takes
  # minutes, and an operator who turns the option off or narrows the window in the middle
  # of one expects it to stop at the next file, not twenty files later.
  def enabled?
    history_media.enabled?(inbox.channel.reload.provider_config)
  end

  # The file leaves the queue once it has been dealt with, not when it is picked: a worker
  # that stops in the middle of a download hands the job back, and the next run starts
  # with the same file instead of leaving it pending with nothing to ask for it.
  def drain
    BATCH.times do
      break if Time.current >= @deadline
      return finish unless enabled?

      id = newest
      return finish if id.nil?

      fetch(Message.find_by(id: id))
      Redis::Alfred.with { |conn| conn.zrem(queue_key, id) }
    end
    again
  rescue *TRANSIENT => e
    Rails.logger.warn("[WHATSAPP SESSION] history media of inbox ##{inbox.id} paused: #{e.message}")
    again(UNAVAILABLE_WAIT)
  end

  # Before anything queues the next run, which could otherwise start, find this run's claim
  # and leave, stopping the drain.
  def release = Redis::Alfred.delete_if_equals(self.class.run_key(inbox), @run)

  def again(wait = 0)
    release
    self.class.set(wait: wait).perform_later(inbox)
  rescue StandardError
    # As in `kick`: nothing was queued, so the scheduling claim must not outlive this run,
    # or the sweep could not start the next one for the claim's whole hour.
    Redis::Alfred.delete(self.class.scheduled_key(inbox))
    raise
  end

  def newest = Redis::Alfred.with { |conn| conn.zrevrange(queue_key, 0, 0) }.first

  # The window is read again here and not only when the file was queued: a dump takes
  # hours to work through, and an operator may have narrowed it in between.
  #
  # A failure that is not the file's own (HistoryMedia.fetch) fails the run with the file
  # still at the head, and the retry, or the sweep after it, finds the whole queue where it
  # was once the problem is fixed.
  def fetch(message)
    return if message.nil? || !history_media.pending?(message)
    return if message.created_at < history_media.cutoff(inbox.channel)

    history_media.fetch(message)
  end

  # Cleared before looking again, so a file queued or a rescan asked for between the last
  # look and this line either sees the flag gone and kicks its own run, or is found here.
  # The run claim goes first: a run kicked once scheduling reopens must not find this one
  # still working and leave, holding the scheduling claim with nobody behind it.
  def finish
    release
    Redis::Alfred.delete(self.class.scheduled_key(inbox))
    pending = Redis::Alfred.zcard(queue_key).positive? || Redis::Alfred.exists?(self.class.requeue_key(inbox))
    self.class.kick(inbox) if pending && enabled?
  end
end
