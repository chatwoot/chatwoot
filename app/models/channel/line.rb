# == Schema Information
#
# Table name: channel_line
#
#  id                  :bigint           not null, primary key
#  line_channel_secret :string           not null
#  line_channel_token  :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :integer          not null
#  line_channel_id     :string           not null
#
# Indexes
#
#  index_channel_line_on_line_channel_id  (line_channel_id) UNIQUE
#

class Channel::Line < ApplicationRecord
  include Channelable

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  if Chatwoot.encryption_configured?
    encrypts :line_channel_secret
    encrypts :line_channel_token
  end

  self.table_name = 'channel_line'
  EDITABLE_ATTRS = [:line_channel_id, :line_channel_secret, :line_channel_token].freeze

  validates :line_channel_id, uniqueness: true, presence: true
  validates :line_channel_secret, presence: true
  validates :line_channel_token, presence: true

  def name
    'LINE'
  end

  def client
    messaging_api_client
  end

  def messaging_api_client
    @messaging_api_client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: line_channel_token,
      http_options: http_options
    )
  end

  def messaging_api_blob_client
    @messaging_api_blob_client ||= Line::Bot::V2::MessagingApi::ApiBlobClient.new(
      channel_access_token: line_channel_token,
      http_options: http_options
    )
  end

  def notification_message_http_client
    @notification_message_http_client ||= Line::Bot::V2::HttpClient.new(
      base_url: 'https://api.line.me',
      http_headers: { 'Authorization' => "Bearer #{line_channel_token}" },
      http_options: http_options
    )
  end

  def webhook_parser
    @webhook_parser ||= Line::Bot::V2::WebhookParser.new(
      channel_secret: line_channel_secret
    )
  end

  private

  def http_options
    return {} unless Rails.env.development?

    # Skip SSL verification in development to avoid certificate issues.
    { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  end
end
