require 'rails_helper'

RSpec.describe EvolutionGo::SyncStateService do
  describe '#perform' do
    let(:account) { create(:account) }
    let(:instance_name) { 'chatwit-test-instance' }
    let(:phone_number) { '+558586488281' }
    let(:jid) { "#{phone_number.delete('+')}@s.whatsapp.net" }
    let(:client) { instance_double(EvolutionGo::Client) }
    let(:provision_service) { instance_double(EvolutionGo::ProvisionService, perform: true) }
    let(:channel) do
      create(
        :channel_whatsapp,
        account: account,
        provider: 'evolution_go',
        phone_number: phone_number,
        provider_config: {
          'instance_name' => instance_name,
          'connection_status' => 'connected',
          'connected' => true,
          'logged_in' => true,
          'jid' => jid
        },
        validate_provider_config: false,
        sync_templates: false
      )
    end

    before do
      allow(EvolutionGo::ProvisionService).to receive(:new).and_return(provision_service)
      allow(EvolutionGo::Client).to receive(:new).and_return(client)
    end

    it 'keeps an expired session on the QR step when the API returns a QR code' do
      allow(client).to receive(:find_instance_by_name).and_return(
        { 'id' => 'instance-id', 'connected' => true, 'jid' => jid }
      )
      allow(client).to receive(:fetch_status).and_return(
        { 'connected' => true, 'loggedIn' => false, 'myJid' => jid }
      )
      allow(client).to receive(:fetch_qr_code).and_return(
        { 'qrcode' => 'data:image/png;base64,qr' }
      )

      with_modified_env FRONTEND_URL: 'https://chatwit.test' do
        state = described_class.new(channel: channel).perform

        expect(state['connection_status']).to eq('awaiting_qr')
        expect(state['qr_code']).to eq('data:image/png;base64,qr')
        expect(channel.reload.provider_config['connection_status']).to eq('awaiting_qr')
      end
    end
  end
end
