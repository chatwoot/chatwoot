# == Schema Information
#
# Table name: channel_stringee
#
#  id           :bigint           not null, primary key
#  phone_number :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#  number_id    :string           not null
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
  validates :number_id, presence: true
  validates :queue_id, presence: true

  def name
    'Stringee'
  end
end
