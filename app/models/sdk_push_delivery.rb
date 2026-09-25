# == Schema Information
#
# Table name: sdk_push_deliveries
#
#  id                    :bigint           not null, primary key
#  reason                :string
#  status                :string           default("pending"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  apns_id               :string           not null
#  message_id            :bigint
#  sdk_push_device_id :bigint           not null
#
# Indexes
#
#  index_sdk_push_deliveries_on_message                (sdk_push_device_id,message_id) UNIQUE
#  index_sdk_push_deliveries_on_message_id             (message_id)
#  index_sdk_push_deliveries_on_sdk_push_device_id  (sdk_push_device_id)
#
# Foreign Keys
#
#  fk_rails_...  (message_id => messages.id)
#  fk_rails_...  (sdk_push_device_id => sdk_push_devices.id)
#
class SdkPushDelivery < ApplicationRecord
  belongs_to :sdk_push_device
  belongs_to :message, optional: true

  before_validation :set_apns_id, on: :create
  validates :status, inclusion: { in: %w[pending accepted rejected] }

  private

  def set_apns_id
    self.apns_id ||= SecureRandom.uuid
  end
end
