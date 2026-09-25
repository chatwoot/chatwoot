# == Schema Information
#
# Table name: mobile_push_devices
#
#  id               :bigint           not null, primary key
#  device_token     :string           not null
#  environment      :string           not null
#  invalidated_at   :datetime
#  name             :string           not null
#  registered_at    :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  contact_id       :bigint           not null
#  contact_inbox_id :bigint           not null
#  mobile_app_id    :bigint           not null
#
# Indexes
#
#  index_mobile_push_devices_on_contact_id        (contact_id)
#  index_mobile_push_devices_on_contact_inbox_id  (contact_inbox_id)
#  index_mobile_push_devices_on_mobile_app_id     (mobile_app_id)
#  index_mobile_push_devices_on_token             (mobile_app_id,environment,device_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (contact_inbox_id => contact_inboxes.id)
#  fk_rails_...  (mobile_app_id => mobile_apps.id)
#
class MobilePushDevice < ApplicationRecord
  belongs_to :mobile_app
  belongs_to :contact_inbox
  belongs_to :contact
  has_many :mobile_push_deliveries, dependent: :destroy

  validates :device_token, presence: true, format: { with: /\A[0-9a-f]+\z/ }, length: { maximum: 512 }
  validates :device_token, uniqueness: { scope: [:mobile_app_id, :environment] }
  validates :environment, inclusion: { in: %w[development production] }
  validates :name, presence: true, length: { maximum: 100 }
  validate :session_matches_inbox

  private

  def session_matches_inbox
    return if contact_inbox.inbox_id == mobile_app.inbox_id && contact_inbox.contact_id == contact_id

    errors.add(:contact_inbox, 'must belong to the current customer and inbox')
  end
end
