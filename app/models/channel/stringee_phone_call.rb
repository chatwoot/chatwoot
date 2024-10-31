# == Schema Information
#
# Table name: channel_stringee
#
#  id           :bigint           not null, primary key
#  phone_number :string           not null
#  route_type   :integer          default("group"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#  group_id     :text
#  queue_id     :string           not null
#
# Indexes
#
#  index_channel_stringee_on_phone_number                 (phone_number) UNIQUE
#  index_channel_stringee_on_phone_number_and_account_id  (phone_number,account_id) UNIQUE
#
class Channel::StringeePhoneCall < ApplicationRecord
  include Channelable

  self.table_name = 'channel_stringee'

  validates :account_id, presence: true
  validates :phone_number, presence: true
  validates :phone_number, uniqueness: true
  validates :queue_id, presence: true

  enum route_type: { by_group: 0, from_list: 1 }

  def name
    'PhoneCall'
  end
end
