require 'rails_helper'

describe Whatsapp::ChannelCreationService do
  let(:account) { create(:account) }
  let(:waba_info) { { waba_id: 'test_waba_id', business_name: 'Test Business' } }
  let(:phone_info) do
    {
      phone_number_id: 'test_phone_id',
      phone_number: '+1234567890',
      verified: true,
      business_name: 'Test Business'
    }
  end
  let(:access_token) { 'test_access_token' }
  let(:service) { described_class.new(account, waba_info, phone_info, access_token) }

  describe '#perform' do
    before do
      # Stub the webhook teardown service to prevent HTTP calls during cleanup
      teardown_service = instance_double(Whatsapp::WebhookTeardownService)
      allow(Whatsapp::WebhookTeardownService).to receive(:new).and_return(teardown_service)
      allow(teardown_service).to receive(:perform)

      # Clean up any existing channels to avoid phone number conflicts
      Channel::Whatsapp.destroy_all

      # Stub the webhook setup service to prevent HTTP calls during tests
      webhook_service = instance_double(Whatsapp::WebhookSetupService)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
      allow(webhook_service).to receive(:perform)

      # Stub the provider validation and sync_templates
      allow(Channel::Whatsapp).to receive(:new).and_wrap_original do |method, *args|
        channel = method.call(*args)
        allow(channel).to receive(:validate_provider_config)
        allow(channel).to receive(:sync_templates)
        channel
      end
    end

    context 'when channel does not exist' do
      it 'creates a new channel' do
        expect { service.perform }.to change(Channel::Whatsapp, :count).by(1)
      end

      it 'creates channel with correct attributes' do
        channel = service.perform
        expect(channel.phone_number).to eq('+1234567890')
        expect(channel.provider).to eq('whatsapp_cloud')
        expect(channel.provider_config['api_key']).to eq(access_token)
        expect(channel.provider_config['phone_number_id']).to eq('test_phone_id')
        expect(channel.provider_config['business_account_id']).to eq('test_waba_id')
        expect(channel.provider_config['source']).to eq('embedded_signup')
      end

      it 'creates an inbox for the channel' do
        channel = service.perform
        inbox = channel.inbox
        expect(inbox).not_to be_nil
        expect(inbox.name).to eq('Test Business WhatsApp')
        expect(inbox.account).to eq(account)
      end
    end

    context 'when channel already exists' do
      before do
        create(:channel_whatsapp, account: account, phone_number: '+1234567890',
                                  provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/Channel already exists/)
      end
    end

    context 'when required parameters are missing' do
      it 'raises error when account is nil' do
        service = described_class.new(nil, waba_info, phone_info, access_token)
        expect { service.perform }.to raise_error(ArgumentError, 'Account is required')
      end

      it 'raises error when waba_info is nil' do
        service = described_class.new(account, nil, phone_info, access_token)
        expect { service.perform }.to raise_error(ArgumentError, 'WABA info is required')
      end

      it 'raises error when phone_info is nil' do
        service = described_class.new(account, waba_info, nil, access_token)
        expect { service.perform }.to raise_error(ArgumentError, 'Phone info is required')
      end

      it 'raises error when access_token is blank' do
        service = described_class.new(account, waba_info, phone_info, '')
        expect { service.perform }.to raise_error(ArgumentError, 'Access token is required')
      end
    end

    context 'when business_name is in different places' do
      context 'when business_name is only in phone_info' do
        let(:waba_info) { { waba_id: 'test_waba_id' } }

        it 'uses business_name from phone_info' do
          channel = service.perform
          expect(channel.inbox.name).to eq('Test Business WhatsApp')
        end
      end

      context 'when business_name is only in waba_info' do
        let(:phone_info) do
          {
            phone_number_id: 'test_phone_id',
            phone_number: '+1234567890',
            verified: true
          }
        end

        it 'uses business_name from waba_info' do
          channel = service.perform
          expect(channel.inbox.name).to eq('Test Business WhatsApp')
        end
      end
    end
  end
end
