require 'rails_helper'

describe Whatsapp::IncomingMessageWhatsappCloudService do
  describe '#perform' do
    let!(:whatsapp_channel) do
      ch = build(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false,
                 provider_config: { 'api_key' => 'test_cloud_key', 'phone_number_id' => 'test_phone_id', 'business_account_id' => 'test_business_id' })
      # Explicitly bypass validation to prevent provider config validation errors
      ch.define_singleton_method(:validate_provider_config) { true }
      ch.define_singleton_method(:sync_templates) { nil }
      
      # Mock the provider_config_object to prevent real API calls during channel operations
      mock_config = double('MockProviderConfig')
      allow(mock_config).to receive(:validate_config?).and_return(true)
      allow(mock_config).to receive(:api_key).and_return('test_cloud_key')
      allow(mock_config).to receive(:phone_number_id).and_return('test_phone_id')
      allow(mock_config).to receive(:business_account_id).and_return('test_business_id')
      allow(mock_config).to receive(:cleanup_on_destroy)
      allow(ch).to receive(:provider_config_object).and_return(mock_config)
      
      ch.save!(validate: false)
      ch
    end
    let!(:inbox) { create(:inbox, channel: whatsapp_channel) }
    
    # Add WebMock stubs for WhatsApp Cloud API calls to prevent external requests during tests
    before do
      # Stub WhatsApp Cloud API calls
      stub_request(:get, %r{https://graph\.facebook\.com/v\d+\.\d+/.*/message_templates})
        .to_return(status: 200, body: '{"data": []}', headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r{https://graph\.facebook\.com/v\d+\.\d+/.*})
        .to_return(status: 200, body: '{"url": "https://example.com/media.jpg"}', headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, 'https://example.com/media.jpg')
        .to_return(status: 200, body: File.read('spec/assets/sample.png'), headers: { 'Content-Type' => 'image/jpeg' })
    end
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              contacts: [{ profile: { name: 'Sojan Jose' }, wa_id: '2423423243' }],
              messages: [{
                from: '2423423243',
                image: {
                  id: 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                  mime_type: 'image/jpeg',
                  sha256: '29ed500fa64eb55fc19dc4124acb300e5dcca0f822a301ae99944db',
                  caption: 'Check out my product!'
                },
                timestamp: '1664799904', type: 'image'
              }]
            }
          }]
        }]
      }.with_indifferent_access
    end

    context 'when valid attachment message params' do
      it 'creates appropriate conversations, message and contacts' do
        stub_request(:get, whatsapp_channel.media_url('b1c68f38-8734-4ad3-b4a1-ef0c10d683')).to_return(
          status: 200,
          body: {
            messaging_product: 'whatsapp',
            url: 'https://chatwoot-assets.local/sample.png',
            mime_type: 'image/jpeg',
            sha256: 'sha256',
            file_size: 'SIZE',
            id: 'b1c68f38-8734-4ad3-b4a1-ef0c10d683'
          }.to_json,
          headers: { 'content-type' => 'application/json' }
        )
        stub_request(:get, 'https://chatwoot-assets.local/sample.png').to_return(
          status: 200,
          body: File.read('spec/assets/sample.png')
        )

        described_class.new(inbox: inbox, params: params).perform
        expect(inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(inbox.messages.first.content).to eq('Check out my product!')
        expect(inbox.messages.first.attachments.present?).to be true
      end

      it 'increments reauthorization count if fetching attachment fails' do
        stub_request(:get, whatsapp_channel.media_url('b1c68f38-8734-4ad3-b4a1-ef0c10d683')).to_return(
          status: 401
        )

        described_class.new(inbox: inbox, params: params).perform
        expect(inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(inbox.messages.first.content).to eq('Check out my product!')
        expect(inbox.messages.first.attachments.present?).to be false
        expect(whatsapp_channel.authorization_error_count).to eq(1)
      end
    end

    context 'when invalid attachment message params' do
      let(:error_params) do
        {
          phone_number: whatsapp_channel.phone_number,
          object: 'whatsapp_business_account',
          entry: [{
            changes: [{
              value: {
                contacts: [{ profile: { name: 'Sojan Jose' }, wa_id: '2423423243' }],
                messages: [{
                  from: '2423423243',
                  image: {
                    id: 'b1c68f38-8734-4ad3-b4a1-ef0c10d683',
                    mime_type: 'image/jpeg',
                    sha256: '29ed500fa64eb55fc19dc4124acb300e5dcca0f822a301ae99944db',
                    caption: 'Check out my product!'
                  },
                  errors: [{
                    code: 400,
                    details: 'Last error was: ServerThrottle. Http request error: HTTP response code said error. See logs for details',
                    title: 'Media download failed: Not retrying as download is not retriable at this time'
                  }],
                  timestamp: '1664799904', type: 'image'
                }]
              }
            }]
          }]
        }.with_indifferent_access
      end

      it 'with attachment errors' do
        described_class.new(inbox: inbox, params: error_params).perform
        expect(inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(inbox.messages.count).to eq(0)
      end
    end

    context 'when invalid params' do
      it 'will not throw error' do
        described_class.new(inbox: inbox, params: { phone_number: whatsapp_channel.phone_number,
                                                                     object: 'whatsapp_business_account', entry: {} }).perform
        expect(inbox.conversations.count).to eq(0)
        expect(Contact.all.first).to be_nil
        expect(inbox.messages.count).to eq(0)
      end
    end
  end
end
