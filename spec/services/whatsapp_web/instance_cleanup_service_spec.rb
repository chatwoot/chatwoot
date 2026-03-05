require 'rails_helper'

RSpec.describe WhatsappWeb::InstanceCleanupService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_api, account: account, additional_attributes: additional_attributes) }
  let(:additional_attributes) do
    {
      integration_type: 'whatsapp_web',
      whatsapp_web: {
        evolution_base_url: 'http://evolution_api:8080',
        evolution_base_path: '',
        evolution_api_key: 'test-api-key',
        phone: '77066318623',
        instance_name: 'cw_1_77066318623'
      }
    }
  end
  let(:connector_client) { instance_double(WhatsappWeb::ConnectorClient) }
  let(:logger) { instance_double(Logger, error: true) }

  before do
    allow(WhatsappWeb::ConnectorClient).to receive(:new).and_return(connector_client)
  end

  describe '#perform' do
    it 'deletes remote instance when whatsapp web integration is configured' do
      allow(connector_client).to receive(:delete).with('/instance/delete/cw_1_77066318623').and_return({ 'status' => 'SUCCESS' })

      result = described_class.new(channel: channel, logger: logger).perform

      expect(result).to be true
      expect(WhatsappWeb::ConnectorClient).to have_received(:new).with(
        base_url: 'http://evolution_api:8080',
        base_path: '',
        api_key: 'test-api-key'
      )
      expect(connector_client).to have_received(:delete).with('/instance/delete/cw_1_77066318623')
    end

    it 'returns false for non whatsapp web integrations' do
      non_whatsapp_channel = create(:channel_api, account: account, additional_attributes: { integration_type: 'api' })

      result = described_class.new(channel: non_whatsapp_channel, logger: logger).perform

      expect(result).to be false
      expect(WhatsappWeb::ConnectorClient).not_to have_received(:new)
    end

    it 'treats missing instance response as success' do
      allow(connector_client).to receive(:delete).and_return(
        {
          'results' => {
            'error' => true,
            'message' => 'Instance does not exist'
          }
        }
      )

      result = described_class.new(channel: channel, logger: logger).perform

      expect(result).to be true
    end

    it 'uses computed instance name from phone when instance_name is missing' do
      channel.update!(
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: {
            evolution_base_url: 'http://evolution_api:8080',
            evolution_api_key: 'test-api-key',
            phone: '+7 (706) 631-86-23'
          }
        }
      )
      allow(connector_client).to receive(:delete).with("/instance/delete/cw_#{account.id}_77066318623").and_return({ 'status' => 'SUCCESS' })

      result = described_class.new(channel: channel, logger: logger).perform

      expect(result).to be true
      expect(connector_client).to have_received(:delete).with("/instance/delete/cw_#{account.id}_77066318623")
    end

    it 'raises when connector delete fails with non-noop error' do
      allow(connector_client).to receive(:delete).and_raise(
        WhatsappWeb::ConnectorClient::RequestError.new('Connector is unreachable')
      )

      expect do
        described_class.new(channel: channel, logger: logger).perform
      end.to raise_error(WhatsappWeb::ConnectorClient::RequestError, 'Connector is unreachable')
      expect(logger).to have_received(:error)
    end

    it 'does not raise when connector fails because instance is already missing' do
      allow(connector_client).to receive(:delete).and_raise(
        WhatsappWeb::ConnectorClient::RequestError.new(
          'Connector request failed (404): Instance not found',
          response_body: { 'message' => 'Instance not found' }
        )
      )

      result = described_class.new(channel: channel, logger: logger).perform

      expect(result).to be true
      expect(logger).not_to have_received(:error)
    end
  end
end
