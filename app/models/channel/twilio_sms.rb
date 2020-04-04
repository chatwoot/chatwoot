# == Schema Information
#
# Table name: channel_twilio_sms
#
#  id           :bigint           not null, primary key
#  account_sid  :string           not null
#  auth_token   :string           not null
#  phone_number :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#

class Channel::TwilioSms < ApplicationRecord
  self.table_name = 'channel_twilio_sms'

  validates :account_id, presence: true
  validates :account_sid, presence: true
  validates :auth_token, presence: true
  validates :phone_number, presence: true

  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'Twilio SMS'
  end
end
