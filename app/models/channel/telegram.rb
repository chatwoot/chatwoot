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
  self.table_name = 'channel_telegram'

  before_validation :ensure_valid_bot_token, on: :create
  validates :account_id, presence: true
  validates :bot_token, presence: true, uniqueness: true

  has_one :inbox, as: :channel, dependent: :destroy
  before_save :setup_telegram_webhook

  def name
    'Telegram'
  end

  def has_24_hour_messaging_window?
    false
  end

  def telegram_api_url
    "https://api.telegram.org/bot#{bot_token}"
  end

  private

  def ensure_valid_bot_token
    response = HTTParty.get("#{telegram_api_url}/getMe")
    unless response.success?
      self.errors.add(:bot_token, 'invalid token')
      return
    end

    self.bot_name = response.parsed_response['result']['username']
  end

  def setup_telegram_webhook
    response = HTTParty.post("#{telegram_api_url}/setWebhook",
                             body: {
                               url: "#{ENV['FRONTEND_URL']}/webhooks/telegram/#{bot_token}"
                             })
    self.errors.add(:bot_token, 'error setting up the webook') unless response.success?
  end
end
