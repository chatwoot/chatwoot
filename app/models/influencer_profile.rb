class InfluencerProfile < ApplicationRecord
  class InvalidTransitionError < StandardError; end

  VALID_TRANSITIONS = {
    discovered: %i[enriched rejected],
    enriched: %i[approved rejected],
    approved: %i[contacted rejected],
    rejected: %i[discovered],
    contacted: %i[confirmed],
    confirmed: %i[]
  }.freeze

  belongs_to :contact
  belongs_to :account
  has_many :influencer_offers, dependent: :destroy

  enum :status, { discovered: 0, enriched: 2, approved: 3, rejected: 4, contacted: 5, confirmed: 6 }
  enum :apify_status, { apify_none: 0, apify_pending: 1, apify_done: 2, apify_failed: 3 }, prefix: :apify

  validates :username, presence: true, uniqueness: { scope: %i[account_id platform] }
  validates :contact_id, uniqueness: true

  scope :scoreable, -> { where(status: :enriched) }
  scope :actionable, -> { where(status: %i[enriched approved]) }

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
