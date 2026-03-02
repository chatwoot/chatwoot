class InfluencerProfile < ApplicationRecord
  class InvalidTransitionError < StandardError; end

  VALID_TRANSITIONS = {
    discovered: %i[report_pending rejected],
    report_pending: %i[report_fetched rejected],
    report_fetched: %i[approved rejected],
    approved: %i[contacted rejected],
    rejected: %i[discovered],
    contacted: %i[approved]
  }.freeze

  belongs_to :contact
  belongs_to :account

  enum :status, { discovered: 0, report_pending: 1, report_fetched: 2, approved: 3, rejected: 4, contacted: 5 }

  validates :username, presence: true, uniqueness: { scope: %i[account_id platform] }
  validates :contact_id, uniqueness: true

  scope :pending_report, -> { where(status: :report_pending) }
  scope :scoreable, -> { where(status: :report_fetched) }
  scope :actionable, -> { where(status: %i[report_fetched approved]) }

  def transition_to!(new_status)
    allowed = VALID_TRANSITIONS[status.to_sym] || []
    raise InvalidTransitionError, "Cannot transition from #{status} to #{new_status}" unless allowed.include?(new_status.to_sym)

    update!(status: new_status)
  end

  def tier
    case followers_count.to_i
    when 0...10_000 then :nano
    when 10_000...50_000 then :micro
    when 50_000...500_000 then :mid
    else :macro
    end
  end

  def hidden_likes?
    hidden_like_posts_rate.to_f > 0.5
  end

  def report_available?
    report_fetched_at.present?
  end
end
