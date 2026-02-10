class StorefrontToken < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :conversation, optional: true

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def touch_last_used!
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:last_used_at, Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
