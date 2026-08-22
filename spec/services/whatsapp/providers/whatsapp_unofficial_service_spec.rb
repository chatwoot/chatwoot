# frozen_string_literal: true

require 'rails_helper'

describe Whatsapp::Providers::WhatsappUnofficialService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp,
           provider: 'whatsapp_unofficial',
           phone_number: '62829990001',
           validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'Test send',
                     inbox: whatsapp_channel.inbox, source_id: 'external_id')
  end

  let(:companion_base) { 'http://companion.test' }
  let(:success_response) { { id: 'ABGTS_SENT_ID', status: 'sent' } }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }

  def stub_companion(method, path, body: nil, response: success_response, status: 200)
    request = stub_request(method, "#{companion_base}#{path}")
              .with(headers: { 'X-Companion-Token' => 'shared-token' })
    request = request.with(body: body) if body
    request.to_return(status: status, body: response.to_json, headers: response_headers)
  end

  before do
    allow(Whatsapp::CompanionConfig).to receive_messages(
      companion_url: companion_base,
      companion_token: 'shared-token'
    )
  end

  describe '#send_text_message' do
    it 'posts a text payload to the companion /send endpoint and returns the message id' do
      stub_companion(:post, '/send',
                     body: hash_including(
                       identifier: '62829990001',
                       to: '6288888',
                       type: 'text',
                       text: 'Test send'
                     ))

      expect(service.send_message('6288888', message)).to eq 'ABGTS_SENT_ID'
    end
  end

  describe '#send_free_text' do
    it 'posts a plain text payload and returns true on success' do
      stub_companion(:post, '/send',
                     body: hash_including(
                       identifier: '62829990001',
                       to: '6288888',
                       type: 'text',
                       text: 'Campaign blast'
                     ))

      expect(service.send_free_text('6288888', 'Campaign blast')).to be true
    end

    it 'returns false when the companion reports a failure' do
      stub_companion(:post, '/send', status: 400, response: { error: 'bad request' })

      expect(service.send_free_text('6288888', 'Campaign blast')).to be false
    end
  end

  describe '#send_attachment_message' do
    it 'posts an image payload with mediaUrl and caption' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open,
                             filename: 'avatar.png', content_type: 'image/png')
      allow(attachment.file).to receive(:filename).and_return('avatar.png')

      stub_companion(:post, '/send',
                     body: hash_including(
                       identifier: '62829990001',
                       to: '6288888',
                       type: 'image',
                       mediaUrl: anything,
                       caption: 'Test send',
                       filename: 'avatar.png'
                     ))

      expect(service.send_message('6288888', message)).to eq 'ABGTS_SENT_ID'
    end
  end

  describe '#media_url' do
    it 'points at the companion media endpoint for the channel phone number' do
      expect(service.media_url('abc123')).to eq "#{companion_base}/media/62829990001/abc123"
    end
  end

  describe '#api_headers' do
    it 'includes the shared companion token' do
      expect(service.api_headers).to eq('x-companion-token' => 'shared-token')
    end
  end

  describe '#validate_provider_config?' do
    it 'returns true and probes the companion status endpoint' do
      stub_companion(:get, '/status/62829990001', response: { status: 'connected' })

      expect(service.validate_provider_config?).to be true
    end

    it 'still returns true when the companion is unreachable so the inbox stays saveable' do
      stub_request(:get, "#{companion_base}/status/62829990001")
        .with(headers: { 'X-Companion-Token' => 'shared-token' })
        .to_timeout

      expect(service.validate_provider_config?).to be true
    end
  end

  describe '#sync_templates' do
    it 'stamps templates as updated without touching the companion' do
      expect(whatsapp_channel).to receive(:mark_message_templates_updated)
      service.sync_templates
      expect(a_request(:post, "#{companion_base}/send")).not_to have_been_made
    end
  end

  describe '#send_template' do
    it 'degrades to a free-form text send of the template name' do
      stub_companion(:post, '/send',
                     body: hash_including(
                       identifier: '62829990001',
                       to: '6288888',
                       type: 'text',
                       text: 'template_named'
                     ))

      expect(service.send_template('6288888', { name: 'template_named' }, message)).to eq 'ABGTS_SENT_ID'
    end
  end
end
