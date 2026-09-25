class MobilePushDevice < ApplicationRecord
  belongs_to :sdk_app
  belongs_to :contact_inbox
  belongs_to :contact
  has_many :mobile_push_deliveries, dependent: :destroy

  validates :device_token, presence: true, format: { with: /\A[0-9a-f]+\z/ }, length: { maximum: 512 }
  validates :device_token, uniqueness: { scope: [:sdk_app_id, :platform, :environment] }
  validates :platform, inclusion: { in: %w[ios] }
  validates :environment, inclusion: { in: %w[development production] }
  validates :name, presence: true, length: { maximum: 100 }
  validate :session_matches_inbox

  private

  def session_matches_inbox
    return if contact_inbox.inbox_id == sdk_app.inbox_id && contact_inbox.contact_id == contact_id

    errors.add(:contact_inbox, 'must belong to the current customer and inbox')
  end
end
