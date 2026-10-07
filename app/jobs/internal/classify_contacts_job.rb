# Walks the contacts table by primary key so that every contact gets the right type and, when the
# REMOVE_STALE_VISITOR_CONTACTS setting is on, stale visitors are removed. The walk only goes as far as the
# last contact created before the retention period, and remembers where it stopped: the first run covers the
# whole table, each daily run after it covers the contacts that crossed the retention line since. Each run
# works for a few seconds and hands the rest to the next run, so a deploy or a restart only pauses it.
#
#   Redis::Alfred.set(Redis::Alfred::CONTACT_CLASSIFY_PAUSED, 1)     # pause
#   Redis::Alfred.delete(Redis::Alfred::CONTACT_CLASSIFY_PAUSED)     # resume
#   Redis::Alfred.set(Redis::Alfred::CONTACT_CLASSIFY_RATE, 500)     # rows written per second
class Internal::ClassifyContactsJob < ApplicationJob
  queue_as :async_database_migration
  retry_on StandardError, wait: 5.minutes, attempts: 12

  WINDOW = 20_000
  MIN_WINDOW = 1_000
  RUN_FOR = 15.seconds
  RECHECK_PAUSE_IN = 5.minutes
  RUNNING_FOR = 30.minutes

  # The daily run starts a walk without arguments; each run of a walk passes its position to the next.
  def perform(cursor = nil, max_id = nil, window = WINDOW)
    return if cursor.nil? && running?

    mark_running
    cursor ||= Redis::Alfred.get(Redis::Alfred::CONTACT_CLASSIFY_CURSOR).to_i + 1
    max_id ||= last_id_before(Contacts::ClassifyVisitorsService::RETENTION.ago)
    return self.class.set(wait: RECHECK_PAUSE_IN).perform_later(cursor, max_id, window) if paused?

    cursor, window = walk(cursor, max_id, window)
    return self.class.perform_later(cursor, max_id, window) if cursor <= max_id

    Redis::Alfred.delete(Redis::Alfred::CONTACT_CLASSIFY_RUNNING)
    Rails.logger.info "[#{self.class.name}] caught up to contact id #{max_id}"
  end

  private

  def walk(cursor, max_id, window)
    deadline = RUN_FOR.from_now
    while cursor <= max_id && Time.current < deadline
      span = size(window)
      to_id = [cursor + span - 1, max_id].min
      counts = classify(cursor, to_id)
      next window = shrink(span) unless counts

      Rails.logger.info "[#{self.class.name}] #{cursor}..#{to_id} #{counts.to_json}"
      Redis::Alfred.set(Redis::Alfred::CONTACT_CLASSIFY_CURSOR, to_id)
      cursor = to_id + 1
    end
    [cursor, window]
  end

  # Ids follow creation order, so a binary search over the primary key finds the boundary without a scan.
  def last_id_before(cutoff)
    low = 0
    high = Contact.maximum(:id).to_i
    while low < high
      middle = (low + high + 1) / 2
      created_at = Contact.where(id: middle..).order(:id).pick(:created_at)
      created_at && created_at < cutoff ? low = middle : high = middle - 1
    end
    low
  end

  # Enough ids that a window made only of promotions still finishes in about RUN_FOR at the current pace.
  def size(window)
    bound = [(Contacts::ClassifyVisitorsService.rows_per_second * RUN_FOR.to_i).to_i, 1].max
    [window, bound].min
  end

  # A window too large to read within the statement timeout is read again at half the size.
  def classify(from_id, to_id)
    Contacts::ClassifyVisitorsService.new(from_id: from_id, to_id: to_id).perform
  rescue ActiveRecord::QueryCanceled
    raise if to_id - from_id < MIN_WINDOW

    nil
  end

  def shrink(span)
    [span / 2, MIN_WINDOW].max
  end

  def paused?
    Redis::Alfred.get(Redis::Alfred::CONTACT_CLASSIFY_PAUSED).present?
  end

  def running?
    Redis::Alfred.get(Redis::Alfred::CONTACT_CLASSIFY_RUNNING).present?
  end

  def mark_running
    Redis::Alfred.setex(Redis::Alfred::CONTACT_CLASSIFY_RUNNING, 1, RUNNING_FOR)
  end
end
