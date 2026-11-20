require 'rails_helper'

describe Telegram::DeleteMessageService do
  subject(:service) { described_class.new(message: message) }

  let(:telegram_channel) { create(:channel_telegram) }
  let(:telegram_api_url) { telegram_channel.telegram_api_url }
  let(:connection_id) { 'eooW3KF5WB5HxTD7T826' }
  let(:conversation_attributes) { { 'chat_id' => '123' } }
  let(:conversation) { create(:conversation, inbox: telegram_channel.inbox, additional_attributes: conversation_attributes) }
  let(:message) do
    create(:message, message_type: :outgoing, content: 'test', conversation: conversation,
                     source_id: '101', external_source_ids: { 'telegram_message_ids' => [101, 102] })
  end
  let(:json_headers) { { 'Content-Type' => 'application/json' } }
  let(:success_body) { { ok: true, result: true }.to_json }

  describe '#perform' do
    it 'deletes every telegram message of the message' do
      stub_request(:post, "#{telegram_api_url}/deleteMessages").to_return(status: 200, body: success_body, headers: json_headers)

      service.perform

      expect(a_request(:post, "#{telegram_api_url}/deleteMessages")
        .with(body: { chat_id: '123', message_ids: '[101,102]' })).to have_been_made.once
    end

    it 'falls back to the source_id for messages sent before all ids were recorded' do
      message.update!(external_source_ids: {})
      stub_request(:post, "#{telegram_api_url}/deleteMessages").to_return(status: 200, body: success_body, headers: json_headers)

      service.perform

      expect(a_request(:post, "#{telegram_api_url}/deleteMessages").with(body: hash_including(message_ids: '[101]'))).to have_been_made.once
    end

    it 'raises with the reason from telegram when telegram refuses' do
      stub_request(:post, "#{telegram_api_url}/deleteMessages")
        .to_return(status: 400, body: { ok: false, error_code: 400, description: "Bad Request: message can't be deleted for everyone" }.to_json,
                   headers: json_headers)

      expect { service.perform }.to raise_error do |error|
        expect(error.class.name).to eq('CustomExceptions::ChannelMessageDeleteFailed')
        expect(error.message).to eq("Could not delete the message on Telegram: Bad Request: message can't be deleted for everyone")
      end
    end

    it 'does not call telegram for messages older than 48 hours' do
      message.update!(created_at: 49.hours.ago)

      service.perform

      expect(a_request(:post, /#{telegram_api_url}/o)).not_to have_been_made
    end

    it 'does not call telegram for incoming messages' do
      message.update!(message_type: :incoming)

      service.perform

      expect(a_request(:post, /#{telegram_api_url}/o)).not_to have_been_made
    end

    it 'does not call telegram for private notes' do
      message.update!(private: true)

      service.perform

      expect(a_request(:post, /#{telegram_api_url}/o)).not_to have_been_made
    end

    it 'does not call telegram for a message that never reached telegram' do
      message.update!(source_id: nil, external_source_ids: {})

      service.perform

      expect(a_request(:post, /#{telegram_api_url}/o)).not_to have_been_made
    end

    context 'when the conversation is a business chat' do
      let(:conversation_attributes) { { 'chat_id' => '123', 'business_connection_id' => connection_id } }

      it 'deletes through the business connection' do
        stub_request(:post, "#{telegram_api_url}/deleteBusinessMessages").to_return(status: 200, body: success_body, headers: json_headers)

        service.perform

        expect(a_request(:post, "#{telegram_api_url}/deleteBusinessMessages")
          .with(body: { business_connection_id: connection_id, message_ids: '[101,102]' })).to have_been_made.once
      end
    end
  end
end
