class InfluencerOffer < ApplicationRecord
  belongs_to :influencer_profile
  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true

  enum :status, { pending: 0, accepted: 1, expired: 2, revoked: 3 }

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  validates :token, presence: true, uniqueness: true

  def offer_path
    "/offer/#{token}"
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def calculate_voucher_value(packages, rights)
    Influencers::VoucherCalculator.new(
      followers: influencer_profile.followers_count,
      fqs_score: influencer_profile.fqs_score,
      packages: packages,
      rights: rights
    ).value
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(24)
  end

  def set_expiry
    self.expires_at ||= 14.days.from_now
  end
end
