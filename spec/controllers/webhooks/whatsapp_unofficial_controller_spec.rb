# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks::WhatsappUnofficialController', type: :request do
  let(:channel) do
    create(:channel_whatsapp,
           provider: 'whatsapp_unofficial',
           phone_number: '15550001111',
           sync_templates: false, validate_provider_config: false)
  end
  let(:body) do
    {
      entry: [{
        id: '15550001111',
        changes: [{
          field: 'messages',
          value: {
            metadata: { display_phone_number: '15550001111', phone_number_id: '15550001111' },
            contacts: [{ profile: { name: 'Customer' }, wa_id: '15551234567' }],
            messages: [{ from: '15551234567', id: 'wamid.test', type: 'text', text: { body: 'hi' } }]
          }
        }]
      }]
    }.to_json
  end

  before do
    allow(Whatsapp::CompanionConfig).to receive(:companion_token).and_return('shared-token')
  end

  def post_unofficial(path, body, token: 'shared-token')
    post path,
         params: body,
         headers: { 'CONTENT_TYPE' => 'application/json', 'x-companion-token' => token }
  end

  after do
    cleanup_message_source_locks
  end

  describe 'POST /webhooks/whatsapp_unofficial/{:phone_number}' do
    it 'rejects requests with a missing/wrong companion token' do
      post_unofficial("/webhooks/whatsapp_unofficial/#{channel.phone_number}", body, token: 'wrong')
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects unknown phone numbers' do
      post_unofficial('/webhooks/whatsapp_unofficial/00000000000', body)
      expect(response).to have_http_status(:not_found)
    end

    it 'enqueues the events job for a valid token' do
      # The companion posts Cloud-shaped payloads; the job routes unofficial to the
      # Cloud parser, so we assert it is enqueued with the parsed params.
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later).with(include('entry'))

      post_unofficial("/webhooks/whatsapp_unofficial/#{channel.phone_number}", body)

      expect(response).to have_http_status(:ok)
    end

    it 'creates a conversation and incoming message for a real inbound message' do
      # Prove the message actually lands in Chatwoot: run the enqueued job inline
      # so the full companion -> controller -> job -> cloud-parser path executes.
      Sidekiq::Testing.inline! do
        post_unofficial("/webhooks/whatsapp_unofficial/#{channel.phone_number}", body)
      end

      expect(response).to have_http_status(:ok)

      conversation = channel.inbox.conversations.last
      expect(conversation).to be_present
      expect(conversation.messages.incoming.last).to have_attributes(
        content: 'hi',
        source_id: 'wamid.test'
      )
    end
  end

  def cleanup_message_source_locks
    Redis::Alfred.scan_each(match: 'MESSAGE_SOURCE_KEY::*') { |key| Redis::Alfred.delete(key) }
  end
end
