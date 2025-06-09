# == Schema Information
#
# Table name: channel_whatsapp_unofficials
#
#  id           :bigint           not null, primary key
#  phone_number :string           not null
#  token        :string
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
  EDITABLE_ATTRS = [:token].freeze

  validates :phone_number, presence: true
  validates :account_id, presence: true
  validates :webhook_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'WhatsApp (Unofficial)'
  end

  def send_message(to:, message:, url: nil)
    Fonnte::FonnteService.new.send_message(to: to, message: message, token: token, url: url)
  end

  def set_token
    device_token = Fonnte::FonnteService.new.device_token(phone_number)
    update!(token: device_token) if device_token
  end
end
