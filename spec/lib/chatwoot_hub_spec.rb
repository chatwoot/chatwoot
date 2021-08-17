require 'rails_helper'

describe ChatwootHub do
  it 'generates installation identifier' do
    installation_identifier = described_class.installation_identifier
    expect(installation_identifier).not_to eq nil
    expect(described_class.installation_identifier).to eq installation_identifier
  end

  context 'when fetching latest_version' do
    it 'get latest version from chatwoot hub' do
      version = '1.1.1'
      allow(RestClient).to receive(:post).and_return({ version: version }.to_json)
      expect(described_class.latest_version).to eq version
      expect(RestClient).to have_received(:post).with(described_class::PING_URL, described_class.instance_config
        .merge(described_class.instance_metrics).to_json, { content_type: :json, accept: :json })
    end

    it 'will not send instance metrics when telemetry is disabled' do
      version = '1.1.1'
      ENV['DISABLE_TELEMETRY'] = 'true'
      allow(RestClient).to receive(:post).and_return({ version: version }.to_json)
      expect(described_class.latest_version).to eq version
      expect(RestClient).to have_received(:post).with(described_class::PING_URL,
                                                      described_class.instance_config.to_json, { content_type: :json, accept: :json })
      ENV['DISABLE_TELEMETRY'] = nil
    end

    it 'returns nil when chatwoot hub is down' do
      allow(RestClient).to receive(:post).and_raise(ExceptionList::REST_CLIENT_EXCEPTIONS.sample)
      expect(described_class.latest_version).to eq nil
    end
  end

  context 'when register instance' do
    let(:company_name) { 'test' }
    let(:owner_name) { 'test' }
    let(:owner_email) { 'test@test.com' }

    it 'sends info of registration' do
      info = { company_name: company_name, owner_name: owner_name, owner_email: owner_email, subscribed_to_mailers: true }
      allow(RestClient).to receive(:post)
      described_class.register_instance(company_name, owner_name, owner_email)
      expect(RestClient).to have_received(:post).with(described_class::REGISTRATION_URL,
                                                      info.merge(described_class.instance_config).to_json, { content_type: :json, accept: :json })
    end
  end

  context 'when sending events' do
    let(:event_name) { 'sample_event' }
    let(:event_data) { { 'sample_data' => 'sample_data' } }

    it 'will send instance events' do
      info = { event_name: event_name, event_data: event_data }
      allow(RestClient).to receive(:post)
      described_class.emit_event(event_name, event_data)
      expect(RestClient).to have_received(:post).with(described_class::EVENTS_URL,
                                                      info.merge(described_class.instance_config).to_json, { content_type: :json, accept: :json })
    end

    it 'will not send instance events when telemetry is disabled' do
      ENV['DISABLE_TELEMETRY'] = 'true'
      info = { event_name: event_name, event_data: event_data }
      allow(RestClient).to receive(:post)
      described_class.emit_event(event_name, event_data)
      expect(RestClient).not_to have_received(:post).with(described_class::EVENTS_URL,
                                                          info.merge(described_class.instance_config).to_json, { content_type: :json, accept: :json })
      ENV['DISABLE_TELEMETRY'] = nil
    end
  end
end
