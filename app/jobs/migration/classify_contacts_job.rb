# Walks the contacts table once, by primary key, so that every existing contact gets the right type and
# stale visitors are removed. Each run works for a few seconds and hands the rest to the next run, so a
# deploy or a restart only pauses it. Every window is safe to repeat.
#
#   Redis::Alfred.set(Redis::Alfred::CONTACT_TYPE_BACKFILL_PAUSED, 1)    # pause
#   Redis::Alfred.delete(Redis::Alfred::CONTACT_TYPE_BACKFILL_PAUSED)    # resume
#   Redis::Alfred.set(Redis::Alfred::CONTACT_TYPE_BACKFILL_RATE, 500)    # rows written per second
#   Migration::ClassifyContactsJob.perform_later                         # restart from where it stopped
class Migration::ClassifyContactsJob < ApplicationJob
  queue_as :async_database_migration
  retry_on StandardError, wait: 5.minutes, attempts: 12

  WINDOW = 20_000
  MIN_WINDOW = 1_000
  RUN_FOR = 15.seconds
  RECHECK_PAUSE_IN = 5.minutes

  def perform(cursor = nil, max_id = nil, window = WINDOW)
    return self.class.set(wait: RECHECK_PAUSE_IN).perform_later(cursor, max_id, window) if paused?

    cursor ||= Redis::Alfred.get(Redis::Alfred::CONTACT_TYPE_BACKFILL_CURSOR).to_i + 1
    max_id ||= Contact.maximum(:id).to_i
    cursor, window = walk(cursor, max_id, window)
    return self.class.perform_later(cursor, max_id, window) if cursor <= max_id

    Redis::Alfred.delete(Redis::Alfred::CONTACT_TYPE_BACKFILL_CURSOR)
    Rails.logger.info "[#{self.class.name}] finished at contact id #{max_id}"
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
      Redis::Alfred.set(Redis::Alfred::CONTACT_TYPE_BACKFILL_CURSOR, to_id)
      cursor = to_id + 1
    end
    [cursor, window]
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
    Redis::Alfred.get(Redis::Alfred::CONTACT_TYPE_BACKFILL_PAUSED).present?
  end
end
