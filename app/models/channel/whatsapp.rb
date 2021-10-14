# == Schema Information
#
# Table name: channel_whatsapp
#
#  id              :bigint           not null, primary key
#  phone_number    :string           not null
#  provider        :string           default("default")
#  provider_config :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_on_phone_number  (phone_number) UNIQUE
#

class Channel::Whatsapp < ApplicationRecord
  include Channelable

  self.table_name = 'channel_whatsapp'
  EDITABLE_ATTRS = [:phone_number, { provider_config: {} }].freeze

  validates :phone_number, presence: true, uniqueness: true
  before_save :validate_provider_config

  def name
    'Whatsapp'
  end

  # all this should happen in provider service . but hack mode on
  def api_base_path
    # provide the environment variable when testing against sandbox : 'https://waba-sandbox.360dialog.io/v1'
    ENV.fetch('360DIALOG_BASE_URL', 'https://waba.360dialog.io/v1')
  end

  # Extract later into provider Service
  def send_message(phone_number, message)
    HTTParty.post(
      "#{api_base_path}/messages",
      headers: { 'D360-API-KEY': provider_config['api_key'], 'Content-Type': 'application/json' },
      body: {
        to: phone_number,
        text: { body: message },
        type: 'text'
      }.to_json
    )
  end

  def has_24_hour_messaging_window?
    true
  end

  private

  # Extract later into provider Service
  def validate_provider_config
    response = HTTParty.post(
      "#{api_base_path}/configs/webhook",
      headers: { 'D360-API-KEY': provider_config['api_key'], 'Content-Type': 'application/json' },
      body: {
        url: "#{ENV['FRONTEND_URL']}/webhooks/whatsapp/#{phone_number}"
      }.to_json
    )
    errors.add(:bot_token, 'error setting up the webook') unless response.success?
  end
end
