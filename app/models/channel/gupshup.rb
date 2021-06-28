
# == Schema Information
#
# Table name: channel_gupshup
#
#  id           :bigint           not null, primary key
#  apikey       :string           not null
#  app          :string           not null
#  phone_number :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :string           not null
#
# Indexes
#
#  index_channel_gupshup_on_account_id    (account_id)
#  index_channel_gupshup_on_phone_number  (phone_number)
#

class Channel::Gupshup < ApplicationRecord
  self.table_name = 'channel_gupshup'

  validates :account_id, presence: true
  validates :app, presence: true
  validates :apikey, presence: true
  validates :phone_number, uniqueness: { scope: :account_id }, presence: true

  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'Gupshup'
  end

  def has_24_hour_messaging_window?
    true
  end
end
