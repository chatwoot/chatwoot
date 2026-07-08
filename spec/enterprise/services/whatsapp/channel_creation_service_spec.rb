# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::ChannelCreationService do
  describe '#perform' do
    let(:account) { create(:account, limits: { inboxes: 1 }) }
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

    before do
      create(:inbox, account: account)

      webhook_service = instance_double(Whatsapp::WebhookSetupService)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
      allow(webhook_service).to receive(:perform)

      allow(Channel::Whatsapp).to receive(:new).and_wrap_original do |method, *args|
        channel = method.call(*args)
        allow(channel).to receive(:validate_provider_config)
        allow(channel).to receive(:sync_templates)
        channel
      end
    end

    it 'raises limit exceeded without leaving an orphan channel' do
      expect do
        expect { service.perform }.to raise_error(
          CustomExceptions::Inbox::LimitExceeded,
          'Account limit exceeded. Upgrade to a higher plan'
        )
      end.not_to change(Channel::Whatsapp, :count)
    end
  end
end
