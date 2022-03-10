# == Schema Information
#
# Table name: channel_telegram
#
#  id         :bigint           not null, primary key
#  bot_name   :string
#  bot_token  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#
# Indexes
#
#  index_channel_telegram_on_bot_token  (bot_token) UNIQUE
#

class Channel::Telegram < ApplicationRecord
  include Channelable

  self.table_name = 'channel_telegram'
  EDITABLE_ATTRS = [:bot_token].freeze

  before_validation :ensure_valid_bot_token, on: :create
  validates :bot_token, presence: true, uniqueness: true
  before_save :setup_telegram_webhook

  def name
    'Telegram'
  end

  def telegram_api_url
    "https://api.telegram.org/bot#{bot_token}"
  end

  def send_message_on_telegram(message)
    return send_message(message) if message.attachments.empty?

    send_attachments(message)
  end

  def get_telegram_profile_image(user_id)
    # get profile image from telegram
    response = HTTParty.get("#{telegram_api_url}/getUserProfilePhotos", query: { user_id: user_id })
    return nil unless response.success?

    photos = response.parsed_response.dig('result', 'photos')
    return if photos.blank?

    get_telegram_file_path(photos.first.last['file_id'])
  end

  def get_telegram_file_path(file_id)
    response = HTTParty.get("#{telegram_api_url}/getFile", query: { file_id: file_id })
    return nil unless response.success?

    "https://api.telegram.org/file/bot#{bot_token}/#{response.parsed_response['result']['file_path']}"
  end

  private

  def ensure_valid_bot_token
    response = HTTParty.get("#{telegram_api_url}/getMe")
    unless response.success?
      errors.add(:bot_token, 'invalid token')
      return
    end

    self.bot_name = response.parsed_response['result']['username']
  end

  def setup_telegram_webhook
    HTTParty.post("#{telegram_api_url}/deleteWebhook")
    response = HTTParty.post("#{telegram_api_url}/setWebhook",
                             body: {
                               url: "#{ENV['FRONTEND_URL']}/webhooks/telegram/#{bot_token}"
                             })
    errors.add(:bot_token, 'error setting up the webook') unless response.success?
  end

  def send_message(message)
    response = message_request(message.conversation[:additional_attributes]['chat_id'], message.content)
    response.parsed_response['result']['message_id'] if response.success?
  end

  def send_attachments(message)
    send_message(message) unless message.content.nil?

    telegram_attachments = []
    message.attachments.each do |attachment|
      telegram_attachment = {}

      case attachment[:file_type]
      when 'image'
        telegram_attachment[:type] = 'photo'
      when 'file'
        telegram_attachment[:type] = 'document'
      end
      telegram_attachment[:media] = attachment.file_url
      telegram_attachments << telegram_attachment
    end

    response = attachments_request(message.conversation[:additional_attributes]['chat_id'], telegram_attachments)
    response.parsed_response['result'].first['message_id'] if response.success?
  end

  def attachments_request(chat_id, attachments)
    HTTParty.post("#{telegram_api_url}/sendMediaGroup",
                  body: {
                    chat_id: chat_id,
                    media: attachments.to_json
                  })
  end

  def message_request(chat_id, text)
    HTTParty.post("#{telegram_api_url}/sendMessage",
                  body: {
                    chat_id: chat_id,
                    text: text
                  })
  end
end
