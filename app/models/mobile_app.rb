# == Schema Information
#
# Table name: mobile_apps
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  private_key :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  bundle_id   :string           not null
#  inbox_id    :bigint           not null
#  key_id      :string           not null
#  team_id     :string           not null
#
# Indexes
#
#  index_mobile_apps_on_inbox_id  (inbox_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (inbox_id => inboxes.id)
#
class MobileApp < ApplicationRecord
  belongs_to :inbox
  has_many :mobile_push_devices, dependent: :destroy

  encrypts :private_key

  validates :name, :bundle_id, :team_id, :key_id, :private_key, presence: true
  validates :name, length: { maximum: 100 }
  validates :bundle_id, format: { with: /\A[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+\z/ }, length: { maximum: 255 }
  validates :team_id, :key_id, format: { with: /\A[A-Z0-9]{10}\z/ }
  validates :inbox_id, uniqueness: true
  validates :private_key, length: { maximum: 8192 }
  validate :unchanged_topic
  validate :website_inbox
  validate :apns_signing_key

  private

  def unchanged_topic
    return unless persisted? && bundle_id_changed? && mobile_push_devices.exists?

    errors.add(:bundle_id, 'cannot change while devices are registered; remove the app configuration first')
  end

  def website_inbox
    errors.add(:inbox, 'must be a Website inbox') unless inbox.web_widget?
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
