# == Schema Information
#
# Table name: channel_twilio_sms
#
#  id                    :bigint           not null, primary key
#  account_sid           :string           not null
#  api_key_sid           :string
#  auth_token            :string           not null
#  medium                :integer          default("sms")
#  messaging_service_sid :string
#  phone_number          :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_channel_twilio_sms_on_account_sid_and_phone_number  (account_sid,phone_number) UNIQUE
#  index_channel_twilio_sms_on_messaging_service_sid         (messaging_service_sid) UNIQUE
#  index_channel_twilio_sms_on_phone_number                  (phone_number) UNIQUE
#

class Channel::TwilioSms < ApplicationRecord
  include Channelable
  include Rails.application.routes.url_helpers

  self.table_name = 'channel_twilio_sms'

  validates :account_sid, presence: true
  # The same parameter is used to store api_key_secret if api_key authentication is opted
  validates :auth_token, presence: true

  EDITABLE_ATTRS = [
    :account_sid,
    :auth_token
  ].freeze

  # Must have _one_ of messaging_service_sid _or_ phone_number, and messaging_service_sid is preferred
  validates :messaging_service_sid, uniqueness: true, presence: true, unless: :phone_number?
  validates :phone_number, absence: true, if: :messaging_service_sid?
  validates :phone_number, uniqueness: true, allow_nil: true

  enum medium: { sms: 0, whatsapp: 1 }

  def name
    medium == 'sms' ? 'Twilio SMS' : 'Whatsapp'
  end

  def send_message(to:, body:, media_url: nil)
    params = send_message_from.merge(to: to, body: body)
    params[:media_url] = media_url if media_url.present?
    params[:status_callback] = twilio_delivery_status_index_url
    client.messages.create(**params)
  end

  private

  def client
    if api_key_sid.present?
      Twilio::REST::Client.new(api_key_sid, auth_token, account_sid)
    else
      Twilio::REST::Client.new(account_sid, auth_token)
    end
  end

  def send_message_from
    if messaging_service_sid?
      { messaging_service_sid: messaging_service_sid }
    else
      { from: phone_number }
    end
  end
end
