require 'rails_helper'

describe ChatwootHub do
  describe '.base_url' do
    it 'uses the static hub url' do
      expect(described_class::DEFAULT_BASE_URL).to eq('https://hub.2.chatwoot.com')
      expect(described_class.base_url).to eq('https://hub.2.chatwoot.com')
    end
  end

  it 'generates installation identifier' do
    installation_identifier = described_class.installation_identifier
    expect(installation_identifier).not_to be_nil
    expect(described_class.installation_identifier).to eq installation_identifier
  end

  context 'when fetching sync_with_hub' do
    it 'get latest version from chatwoot hub' do
      version = '1.1.1'
      response_body = { version: version }.to_json
      mock_response = double(success?: true, body: response_body)
      allow(HTTParty).to receive(:post).and_return(mock_response)
      expect(described_class.sync_with_hub['version']).to eq version
      expect(HTTParty).to have_received(:post).with(
        described_class.ping_url,
        headers: described_class.api_headers,
        body: described_class.instance_config.merge(described_class.instance_metrics).to_json
      )
    end

    it 'will not send instance metrics when telemetry is disabled' do
      version = '1.1.1'
      response_body = { version: version }.to_json
      mock_response = double(success?: true, body: response_body)
      with_modified_env DISABLE_TELEMETRY: 'true' do
        allow(HTTParty).to receive(:post).and_return(mock_response)
        expect(described_class.sync_with_hub['version']).to eq version
        expect(HTTParty).to have_received(:post).with(
          described_class.ping_url,
          headers: described_class.api_headers,
          body: described_class.instance_config.to_json
        )
      end
    end

    it 'returns nil when chatwoot hub is down' do
      allow(HTTParty).to receive(:post).and_raise(SocketError)
      expect(described_class.sync_with_hub).to be_nil
    end
  end

  context 'when register instance' do
    let(:company_name) { 'test' }
    let(:owner_name) { 'test' }
    let(:owner_email) { 'test@test.com' }

    it 'sends info of registration' do
      info = { company_name: company_name, owner_name: owner_name, owner_email: owner_email, subscribed_to_mailers: true }
      allow(HTTParty).to receive(:post)
      described_class.register_instance(company_name, owner_name, owner_email)
      expect(HTTParty).to have_received(:post).with(
        described_class.registration_url,
        headers: described_class.api_headers,
        body: info.merge(described_class.instance_config).to_json
      )
    end
  end

  context 'when sending events' do
    let(:event_name) { 'sample_event' }
    let(:event_data) { { 'sample_data' => 'sample_data' } }

    it 'will send instance events' do
      info = { event_name: event_name, event_data: event_data }
      allow(HTTParty).to receive(:post)
      described_class.emit_event(event_name, event_data)
      expect(HTTParty).to have_received(:post).with(
        described_class.events_url,
        headers: described_class.api_headers,
        body: info.merge(described_class.instance_config).to_json
      )
    end

    it 'will not send instance events when telemetry is disabled' do
      with_modified_env DISABLE_TELEMETRY: 'true' do
        info = { event_name: event_name, event_data: event_data }
        allow(HTTParty).to receive(:post)
        described_class.emit_event(event_name, event_data)
        expect(HTTParty).not_to have_received(:post)
          .with(
            described_class.events_url,
            headers: described_class.api_headers,
            body: info.merge(described_class.instance_config).to_json
          )
      end
    end
  end
end
