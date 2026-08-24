# == Schema Information
#
# Table name: channel_bales
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
#  index_channel_bales_on_bot_token  (bot_token) UNIQUE
#

class Channel::Bale < ApplicationRecord
  include Channelable

  encrypts :bot_token, deterministic: true if Chatwoot.encryption_configured?

  self.table_name = 'channel_bales'
  EDITABLE_ATTRS = [:bot_token].freeze

  before_validation :ensure_valid_bot_token, on: :create
  validates :bot_token, presence: true, uniqueness: true
  before_save :setup_bale_webhook

  def name
    'Bale'
  end

  def bale_api_url
    "https://api.bale.ai/bot#{bot_token}"
  end

  def send_message_on_bale(message)
    message_id = send_message(message) if message.outgoing_content.present?
    message_id = Bale::SendAttachmentsService.new(message: message).perform if message.attachments.present?
    message_id
  end

  def get_bale_profile_image(user_id)
    response = HTTParty.get("#{bale_api_url}/getUserProfilePhotos", query: { user_id: user_id })
    return nil unless response.success?

    photos = response.parsed_response.dig('result', 'photos')
    return if photos.blank?

    get_bale_file_path(photos.first.last['file_id'])
  end

  def get_bale_file_path(file_id)
    response = HTTParty.get("#{bale_api_url}/getFile", query: { file_id: file_id })
    return nil unless response.success?

    "https://api.bale.ai/file/bot#{bot_token}/#{response.parsed_response['result']['file_path']}"
  end

  def process_error(message, response)
    return unless response.parsed_response['ok'] == false

    message.external_error = "#{response.parsed_response['error_code']}, #{response.parsed_response['description']}"
    message.status = :failed
    message.save!
  end

  def chat_id(message)
    message.conversation[:additional_attributes]['chat_id']
  end

  def reply_to_message_id(message)
    message.content_attributes['in_reply_to_external_id']
  end

  private

  def ensure_valid_bot_token
    response = HTTParty.get("#{bale_api_url}/getMe")
    unless response.success?
      errors.add(:bot_token, 'invalid token')
      return
    end

    self.bot_name = response.parsed_response['result']['username']
  end

  def setup_bale_webhook
    HTTParty.post("#{bale_api_url}/deleteWebhook")
    response = HTTParty.post("#{bale_api_url}/setWebhook",
                             body: {
                               url: "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/bale/#{bot_token}"
                             })
    errors.add(:bot_token, 'error setting up the webhook') unless response.success?
  end

  def send_message(message)
    response = message_request(
      chat_id(message),
      message.outgoing_content,
      reply_markup(message),
      reply_to_message_id(message)
    )
    process_error(message, response)
    response.parsed_response['result']['message_id'] if response.success?
  end

  def reply_markup(message)
    return unless message.content_type == 'input_select'

    {
      one_time_keyboard: true,
      inline_keyboard: message.content_attributes['items'].map do |item|
        [{
          text: item['title'],
          callback_data: item['value']
        }]
      end
    }.to_json
  end

  def message_request(chat_id, text, reply_markup = nil, reply_to_message_id = nil)
    HTTParty.post("#{bale_api_url}/sendMessage",
                  body: {
                    chat_id: chat_id,
                    text: text,
                    reply_markup: reply_markup,
                    parse_mode: 'HTML',
                    reply_to_message_id: reply_to_message_id
                  })
  end
end
