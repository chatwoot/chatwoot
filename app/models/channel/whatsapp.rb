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
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def media_url(media_id)
    "#{api_base_path}/media/#{media_id}"
  end

  def api_headers
    { 'D360-API-KEY' => provider_config['api_key'], 'Content-Type' => 'application/json' }
  end

  def has_24_hour_messaging_window?
    true
  end

  private

  def send_text_message(phone_number, message)
    HTTParty.post(
      "#{api_base_path}/messages",
      headers: { 'D360-API-KEY': provider_config['api_key'], 'Content-Type': 'application/json' },
      body: {
        to: phone_number,
        text: { body: message.content },
        type: 'text'
      }.to_json
    )
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    attachment_url = attachment.file_url
    HTTParty.post(
      "#{api_base_path}/messages",
      headers: { 'D360-API-KEY': provider_config['api_key'], 'Content-Type': 'application/json' },
      body: {
        'to' => phone_number,
        'type' => type,
        type.to_s => {
          'link': attachment_url,
          'caption': message.content
        }
      }.to_json
    )
  end

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
