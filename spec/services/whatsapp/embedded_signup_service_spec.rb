require 'rails_helper'

describe Whatsapp::EmbeddedSignupService do
  let(:account) { create(:account) }
  let(:params) do
    {
      code: 'test_authorization_code',
      business_id: 'test_business_id',
      waba_id: 'test_waba_id',
      phone_number_id: 'test_phone_number_id'
    }
  end
  let(:service) { described_class.new(account: account, params: params) }
  let(:access_token) { 'test_access_token' }
  let(:phone_info) do
    {
      phone_number_id: params[:phone_number_id],
      phone_number: '+1234567890',
      verified: true,
      business_name: 'Test Business'
    }
  end
  let(:channel) { instance_double(Channel::Whatsapp) }
  let(:setup_job) { Channels::Whatsapp::EmbeddedSignupSetupJob }

  describe '#perform' do
    before do
      token_exchange = instance_double(Whatsapp::TokenExchangeService)
      allow(Whatsapp::TokenExchangeService).to receive(:new).with(params[:code]).and_return(token_exchange)
      allow(token_exchange).to receive(:perform).and_return(access_token)

      phone_service = instance_double(Whatsapp::PhoneInfoService)
      allow(Whatsapp::PhoneInfoService).to receive(:new)
        .with(params[:waba_id], params[:phone_number_id], access_token, expected_phone_number: anything).and_return(phone_service)
      allow(phone_service).to receive(:perform).and_return(phone_info)

      channel_creation = instance_double(Whatsapp::ChannelCreationService)
      allow(Whatsapp::ChannelCreationService).to receive(:new)
        .with(account, { waba_id: params[:waba_id], business_name: 'Test Business' }, phone_info, access_token)
        .and_return(channel_creation)
      allow(channel_creation).to receive(:perform).and_return(channel)

      allow(setup_job).to receive(:perform_later)
    end

    it 'creates the channel and leaves registration and webhook setup to the setup job' do
      expect(service.perform).to eq(channel)
      expect(setup_job).to have_received(:perform_later).with(channel, is_coexistence: nil, check_health: true)
    end

    it 'skips the health check for coexistence signups' do
      described_class.new(account: account, params: params.merge(is_coexistence: 'true')).perform

      expect(setup_job).to have_received(:perform_later).with(channel, is_coexistence: true, check_health: false)
    end

    context 'when parameters are invalid' do
      it 'raises ArgumentError for missing parameters' do
        invalid_service = described_class.new(account: account, params: { code: '', waba_id: '' })
        expect { invalid_service.perform }.to raise_error(ArgumentError, 'Required parameters are missing: code, waba_id')
      end

      it 'does not require business_id' do
        coexistence_service = described_class.new(account: account, params: params.except(:business_id))
        expect { coexistence_service.perform }.not_to raise_error
      end
    end

    context 'when service fails' do
      it 'logs and re-raises errors without enqueueing setup' do
        token_exchange = instance_double(Whatsapp::TokenExchangeService)
        allow(Whatsapp::TokenExchangeService).to receive(:new).and_return(token_exchange)
        allow(token_exchange).to receive(:perform).and_raise('Token error')

        expect(Rails.logger).to receive(:error).with('[WHATSAPP] Embedded signup failed: Token error')
        expect { service.perform }.to raise_error('Token error')
        expect(setup_job).not_to have_received(:perform_later)
      end
    end

    context 'with reauthorization flow' do
      let(:inbox_id) { 123 }
      let(:reauth_service) { instance_double(Whatsapp::ReauthorizationService) }
      let(:service_with_inbox) { described_class.new(account: account, params: params, inbox_id: inbox_id) }

      before do
        allow(Whatsapp::ReauthorizationService).to receive(:new).with(
          account: account,
          inbox_id: inbox_id,
          phone_number_id: params[:phone_number_id],
          waba_id: params[:waba_id]
        ).and_return(reauth_service)
        allow(reauth_service).to receive(:perform).with(access_token, phone_info).and_return(channel)
      end

      it 'reauthorizes and enqueues setup without the health check' do
        expect(service_with_inbox.perform).to eq(channel)
        expect(setup_job).to have_received(:perform_later).with(channel, is_coexistence: nil, check_health: false)
      end
    end

    # A signup that timed out, or Meta removing our access, leaves the inbox in place; customers then run signup again.
    context 'when this account already has a cloud inbox for the number' do
      let!(:existing_channel) do
        create(:channel_whatsapp, account: account, phone_number: '+1234567890', provider: 'whatsapp_cloud',
                                  validate_provider_config: false, sync_templates: false)
      end
      let(:reauth_service) { instance_double(Whatsapp::ReauthorizationService) }

      before do
        allow(Whatsapp::ReauthorizationService).to receive(:new).with(
          account: account,
          inbox_id: existing_channel.inbox.id,
          phone_number_id: params[:phone_number_id],
          waba_id: params[:waba_id]
        ).and_return(reauth_service)
        allow(reauth_service).to receive(:perform).with(access_token, phone_info).and_return(existing_channel)
      end

      it 'reconnects the existing inbox instead of failing on the duplicate number' do
        expect(service.perform).to eq(existing_channel)
        expect(Whatsapp::ChannelCreationService).not_to have_received(:new)
        expect(setup_job).to have_received(:perform_later).with(existing_channel, is_coexistence: nil, check_health: false)
      end
    end

    context 'when another account already has an inbox for the number' do
      before do
        create(:channel_whatsapp, account: create(:account), phone_number: '+1234567890', provider: 'whatsapp_cloud',
                                  validate_provider_config: false, sync_templates: false)
        allow(Whatsapp::ChannelCreationService).to receive(:new).and_call_original
      end

      it 'still refuses the signup' do
        expect { service.perform }.to raise_error(/\+1234567890/)
        expect(setup_job).not_to have_received(:perform_later)
      end
    end

    # A manual inbox runs on the customer's own Meta app; signup must not switch it to ours.
    context 'when this account has a manually connected inbox for the number' do
      before do
        manual_channel = create(:channel_whatsapp, account: account, phone_number: '+1234567890', provider: 'whatsapp_cloud',
                                                   validate_provider_config: false, sync_templates: false)
        manual_channel.update!(provider_config: manual_channel.provider_config.merge('source' => 'manual_setup_v2', 'app_secret' => 'secret'))
        allow(Whatsapp::ChannelCreationService).to receive(:new).and_call_original
        allow(Whatsapp::ReauthorizationService).to receive(:new)
      end

      it 'refuses the signup instead of taking the inbox over' do
        expect { service.perform }.to raise_error(/\+1234567890/)
        expect(Whatsapp::ReauthorizationService).not_to have_received(:new)
      end
    end
  end
end
