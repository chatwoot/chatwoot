class SdkPushDevice < ApplicationRecord
  belongs_to :sdk_app
  belongs_to :contact_inbox
  belongs_to :contact
  has_many :sdk_push_deliveries, dependent: :destroy

  validates :device_token, presence: true, length: { maximum: 4096 }
  validates :device_token, format: { with: /\A[0-9a-f]+\z/ }, length: { maximum: 512 }, if: -> { platform == 'ios' }
  validates :device_token, format: { with: /\A[A-Za-z0-9_:\-]+\z/ }, if: -> { platform == 'android' }
  validates :device_token, uniqueness: { scope: [:sdk_app_id, :platform, :environment] }
  validates :platform, inclusion: { in: %w[ios android] }
  validates :environment, inclusion: { in: %w[development production] }
  validates :name, presence: true, length: { maximum: 100 }
  validates :environment, inclusion: { in: %w[production] }, if: -> { platform == 'android' }
  validate :session_matches_inbox

  def push_enabled?
    configuration = platform == 'ios' ? sdk_app.ios_configuration : sdk_app.android_configuration
    configuration.enabled?
  end

  private

  def session_matches_inbox
    return if contact_inbox.inbox_id == sdk_app.inbox_id && contact_inbox.contact_id == contact_id

    errors.add(:contact_inbox, 'must belong to the current customer and inbox')
  end
end
