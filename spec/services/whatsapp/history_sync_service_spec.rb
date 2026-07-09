require 'rails_helper'

describe Whatsapp::HistorySyncService do
  let(:channel) do
    create(:channel_whatsapp,
           provider: 'whatsapp_cloud',
           provider_config: {
             'api_key' => 'test_token',
             'phone_number_id' => '123456789',
             'source' => 'embedded_signup'
           },
           sync_templates: false,
           validate_provider_config: false)
  end
  let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }
  let(:service) { described_class.new(channel) }

  before do
    # Isolate from channel-creation webhook setup (fires for non-embedded_signup channels).
    allow_any_instance_of(Channel::Whatsapp).to receive(:setup_webhooks)
    allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
  end

  describe '#perform' do
    context 'when the flag is ON and channel is a coexistence channel' do
      it 'triggers contacts sync first, then history sync, and persists the request ids' do
        # Reason: Meta mandates contacts (smb_app_state_sync) before history, one attempt per cycle.
        allow(api_client).to receive(:start_smb_app_data_sync)
          .with('123456789', 'smb_app_state_sync').and_return({ 'request_id' => 'req_contacts' })
        allow(api_client).to receive(:start_smb_app_data_sync)
          .with('123456789', 'history').and_return({ 'request_id' => 'req_history' })

        with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
          service.perform
        end

        expect(api_client).to have_received(:start_smb_app_data_sync).with('123456789', 'smb_app_state_sync').ordered
        expect(channel.reload.provider_config['history_sync_request_ids']).to eq(
          'smb_app_state_sync' => 'req_contacts', 'history' => 'req_history'
        )
        expect(channel.provider_config['history_sync_requested_at']).to be_present
      end

      it 'is idempotent — a second call does not re-trigger the API' do
        # Reason: re-running the signup flow on the same channel must not double-fire the sync.
        allow(api_client).to receive(:start_smb_app_data_sync).and_return({ 'request_id' => 'req' })

        with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
          service.perform
          described_class.new(channel.reload).perform
        end

        expect(api_client).to have_received(:start_smb_app_data_sync).twice # only the first perform (2 sync types)
      end

      it 'never raises when the API call fails (onboarding must not break)' do
        # Reason: history is best-effort; a Graph API failure cannot bubble up into onboarding.
        allow(api_client).to receive(:start_smb_app_data_sync).and_raise(StandardError, 'graph down')

        with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
          expect { service.perform }.not_to raise_error
        end
        expect(channel.reload.provider_config['history_sync_requested_at']).to be_nil
      end
    end

    context 'when the flag is OFF' do
      it 'does not call the API' do
        # Reason: whole pipeline is gated; flag off means no sync trigger at all.
        allow(api_client).to receive(:start_smb_app_data_sync)
        service.perform
        expect(api_client).not_to have_received(:start_smb_app_data_sync)
      end
    end

    context 'when the channel is not a coexistence (embedded_signup) channel' do
      let(:channel) do
        create(:channel_whatsapp,
               provider: 'whatsapp_cloud',
               provider_config: { 'api_key' => 'test_token', 'phone_number_id' => '123456789', 'source' => 'manual' },
               sync_templates: false,
               validate_provider_config: false)
      end

      it 'does not call the API even with the flag on' do
        # Reason: history sync only applies to Coexistence channels onboarded via Embedded Signup.
        allow(api_client).to receive(:start_smb_app_data_sync)
        with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
          service.perform
        end
        expect(api_client).not_to have_received(:start_smb_app_data_sync)
      end
    end
  end
end
