# frozen_string_literal: true

require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS: check de conexão da instância Avisa (Configurações +
# job agendado 3x/dia). Mapeia /instance/status -> connected|disconnected|unknown,
# persiste o último check e avisa os admins (toast) na queda.
describe Whatsapp::AvisaConnectionCheckService do
  subject(:service) { described_class.new(channel: channel) }

  let(:channel) do
    create(:channel_whatsapp, provider: 'avisa',
                              provider_config: { 'api_key' => 'k', 'base_url' => 'https://avisa.test' },
                              validate_provider_config: false, sync_templates: false)
  end

  def stub_status(status:, body:)
    stub_request(:get, 'https://avisa.test/instance/status')
      .to_return(status: status, body: body.is_a?(String) ? body : body.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  describe '#perform' do
    it 'marca connected e persiste o último check em provider_config' do
      stub_status(status: 200, body: { 'connected' => true })

      result = service.perform

      expect(result.status).to eq('connected')
      expect(channel.reload.provider_config.dig('last_connection_check', 'status')).to eq('connected')
      expect(channel.provider_config.dig('last_connection_check', 'checked_at')).to be_present
    end

    it 'marca disconnected quando a instância caiu' do
      stub_status(status: 200, body: { 'state' => 'close' })

      expect(service.perform.status).to eq('disconnected')
    end

    it 'marca unknown quando indeterminado (5xx)' do
      stub_status(status: 502, body: {})

      expect(service.perform.status).to eq('unknown')
    end
  end

  describe '.broadcast_disconnected' do
    it 'enfileira ActionCableBroadcastJob pros admins com o evento correto' do
      admin = create(:user, account: channel.account, role: :administrator)
      result = described_class::Result.new(status: 'disconnected', http: 200, checked_at: Time.current)

      expect do
        described_class.broadcast_disconnected(channel, result)
      end.to have_enqueued_job(ActionCableBroadcastJob)
        .with(a_collection_including(admin.pubsub_token), 'whatsapp.instance_disconnected', anything)
    end

    it 'não enfileira nada quando não há admins' do
      result = described_class::Result.new(status: 'disconnected', http: 200, checked_at: Time.current)
      allow(channel.account).to receive(:administrators).and_return(User.none)

      expect do
        described_class.broadcast_disconnected(channel, result)
      end.not_to have_enqueued_job(ActionCableBroadcastJob)
    end
  end
end
