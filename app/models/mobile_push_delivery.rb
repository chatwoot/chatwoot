# == Schema Information
#
# Table name: mobile_push_deliveries
#
#  id                    :bigint           not null, primary key
#  reason                :string
#  status                :string           default("pending"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  apns_id               :string           not null
#  message_id            :bigint
#  mobile_push_device_id :bigint           not null
#
# Indexes
#
#  index_mobile_push_deliveries_on_message                (mobile_push_device_id,message_id) UNIQUE
#  index_mobile_push_deliveries_on_message_id             (message_id)
#  index_mobile_push_deliveries_on_mobile_push_device_id  (mobile_push_device_id)
#
# Foreign Keys
#
#  fk_rails_...  (message_id => messages.id)
#  fk_rails_...  (mobile_push_device_id => mobile_push_devices.id)
#
class MobilePushDelivery < ApplicationRecord
  belongs_to :mobile_push_device
  belongs_to :message, optional: true

  before_validation :set_apns_id, on: :create
  validates :status, inclusion: { in: %w[pending accepted rejected] }

  private

  def set_apns_id
    self.apns_id ||= SecureRandom.uuid
  end
end
