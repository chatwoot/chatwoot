class FailedEmailRetryBatch < ApplicationRecord
  LOOKBACK_HOURS = [1, 2, 4, 8, 12, 24].freeze

  belongs_to :requested_by, class_name: 'SuperAdmin'

  enum status: { queued: 0, processing: 1, completed: 2, failed: 3 }

  validates :lookback_hours, inclusion: { in: LOOKBACK_HOURS }
  validates :range_start, :range_end, presence: true
  validates :candidate_count, :eligible_count, :scheduled_count, :skipped_count, :error_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.preview_for(lookback_hours:, range_end: Time.current)
    raise ArgumentError, "Unsupported lookback: #{lookback_hours}" unless LOOKBACK_HOURS.include?(lookback_hours)

    range_start = range_end - lookback_hours.hours
    candidates = candidates_for(range_start: range_start, range_end: range_end)
    candidate_count = candidates.count
    eligible_count = candidates.joins(:account).merge(Account.active).count

    {
      lookback_hours: lookback_hours,
      range_start: range_start,
      range_end: range_end,
      candidate_count: candidate_count,
      eligible_count: eligible_count,
      suspended_count: candidate_count - eligible_count
    }
  end

  def self.candidates_for(range_start:, range_end:)
    Message.unscoped.failed.outgoing
           .where(created_at: range_start..range_end)
           .where('messages.updated_at <= ?', range_end)
           .joins(:inbox)
           .where(inboxes: { channel_type: 'Channel::Email' })
  end

  def candidates
    self.class.candidates_for(range_start: range_start, range_end: range_end)
  end

  def active?
    queued? || processing?
  end
end
