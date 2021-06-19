
# == Schema Information
#
# Table name: channel_gupshup
#
#  id           :bigint           not null, primary key
#  apikey       :string           not null
#  app          :string           not null
#  phone_number :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :string           not null
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
    'Whatsapp'
  end

  def has_24_hour_messaging_window?
    true
  end
end
