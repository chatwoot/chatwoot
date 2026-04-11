require 'rails_helper'

RSpec.describe Channel::Line do
  describe '#messaging_api_client' do
    it 'builds a v2 messaging client with the stored channel access token' do
      channel = build(:channel_line, line_channel_token: 'token-123')

      client = channel.messaging_api_client

      expect(client).to be_a(Line::Bot::V2::MessagingApi::ApiClient)
    end
  end

  describe '#messaging_api_blob_client' do
    it 'builds a v2 blob client with the stored channel access token' do
      channel = build(:channel_line, line_channel_token: 'token-123')

      client = channel.messaging_api_blob_client

      expect(client).to be_a(Line::Bot::V2::MessagingApi::ApiBlobClient)
    end
  end

  describe '#notification_message_http_client' do
    it 'builds an http client for LINE notification message requests' do
      channel = build(:channel_line, line_channel_token: 'token-123')

      client = channel.notification_message_http_client

      expect(client).to be_a(Line::Bot::V2::HttpClient)
    end
  end

  describe '#webhook_parser' do
    it 'builds a v2 webhook parser with the stored channel secret' do
      channel = build(:channel_line, line_channel_secret: 'secret-123')

      parser = channel.webhook_parser

      expect(parser).to be_a(Line::Bot::V2::WebhookParser)
    end
  end
end
