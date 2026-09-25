class SdkIosConfiguration < ApplicationRecord
  belongs_to :sdk_app
  encrypts :private_key

  validates :sdk_app_id, uniqueness: true
  validates :bundle_id, :team_id, :key_id, :private_key, presence: true
  validates :bundle_id, format: { with: /\A[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+\z/ }, length: { maximum: 255 }
  validates :team_id, :key_id, format: { with: /\A[A-Z0-9]{10}\z/ }
  validates :private_key, length: { maximum: 8192 }
  validate :unchanged_topic
  validate :apns_signing_key
  before_destroy :clear_devices

  private

  def clear_devices
    sdk_app.mobile_push_devices.where(platform: 'ios').destroy_all
  end

  def unchanged_topic
    return unless persisted? && bundle_id_changed? && sdk_app.mobile_push_devices.exists?(platform: 'ios')

    errors.add(:bundle_id, 'cannot change while devices are registered; remove the iOS configuration first')
  end

  def apns_signing_key
    return if private_key.blank? || !private_key_changed?

    key = OpenSSL::PKey.read(private_key)
    return if key.is_a?(OpenSSL::PKey::EC) && key.private? && key.group.curve_name == 'prime256v1'

    errors.add(:private_key, 'must be an APNs P-256 private key')
  rescue OpenSSL::PKey::PKeyError, ArgumentError
    errors.add(:private_key, 'must be a valid APNs private key')
  end
end
