# == Schema Information
#
# Table name: queue_statistics
#
#  id                        :bigint           not null, primary key
#  average_wait_time_seconds :integer          default(0), not null
#  date                      :date             not null
#  max_wait_time_seconds     :integer          default(0), not null
#  total_assigned            :integer          default(0), not null
#  total_left                :integer          default(0), not null
#  total_queued              :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :bigint           not null
#
# Indexes
#
#  index_queue_statistics_on_account_id_and_date  (account_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class QueueStatistic < ApplicationRecord
  belongs_to :account

  validates :date, uniqueness: { scope: :account_id }
  validates :total_queued, :total_assigned, :total_left, :average_wait_time_seconds, :max_wait_time_seconds,
            presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Daily counters are updated with a single INSERT ... ON CONFLICT so that concurrent queue
  # entry / assignment / removal flows never read stale values or race on the unique
  # (account_id, date) index. The running average is recomputed inside the statement.
  def self.update_statistics_for(account_id, wait_time_seconds:, assigned: false, left: false)
    wait_time = assigned ? [wait_time_seconds.to_i, 0].max : 0

    upsert_daily(
      account_id,
      total_assigned: assigned ? 1 : 0,
      total_left: left ? 1 : 0,
      average_wait_time_seconds: wait_time,
      max_wait_time_seconds: wait_time
    )
  end

  def self.increment_queued(account_id)
    upsert_daily(account_id, total_queued: 1)
  end

  COUNTER_DEFAULTS = {
    total_queued: 0, total_assigned: 0, total_left: 0, average_wait_time_seconds: 0, max_wait_time_seconds: 0
  }.freeze

  def self.upsert_daily(account_id, counters)
    now = Time.current
    row = COUNTER_DEFAULTS.merge(counters).merge(account_id: account_id, date: Date.current, created_at: now, updated_at: now)

    upsert_all([row], unique_by: [:account_id, :date], on_duplicate: Arel.sql(<<~SQL.squish)) # rubocop:disable Rails/SkipsModelValidations
      total_queued = queue_statistics.total_queued + EXCLUDED.total_queued,
      total_assigned = queue_statistics.total_assigned + EXCLUDED.total_assigned,
      total_left = queue_statistics.total_left + EXCLUDED.total_left,
      average_wait_time_seconds = CASE
        WHEN EXCLUDED.total_assigned = 0 THEN queue_statistics.average_wait_time_seconds
        ELSE (queue_statistics.average_wait_time_seconds * queue_statistics.total_assigned + EXCLUDED.average_wait_time_seconds)
             / (queue_statistics.total_assigned + EXCLUDED.total_assigned)
      END,
      max_wait_time_seconds = GREATEST(queue_statistics.max_wait_time_seconds, EXCLUDED.max_wait_time_seconds),
      updated_at = EXCLUDED.updated_at
    SQL
  end
  private_class_method :upsert_daily
end
