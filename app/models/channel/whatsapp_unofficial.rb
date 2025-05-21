# == Schema Information
#
# Table name: channel_whatsapp_unofficials
#
#  id           :bigint           not null, primary key
#  phone_number :string           not null
#  webhook_url  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_unofficials_on_account_id    (account_id)
#  index_channel_whatsapp_unofficials_on_phone_number  (phone_number) UNIQUE
#

class Channel::WhatsappUnofficial < ApplicationRecord
  include Channelable

  self.table_name = 'channel_whatsapp_unofficials'

  validates :phone_number, presence: true
  validates :account_id, presence: true
  validates :webhook_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'WhatsApp (Unofficial)'
  end
end
