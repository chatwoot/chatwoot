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

  describe '.sync_with_hub' do
    it 'never contacts the hub' do
      allow(RestClient).to receive(:post)
      expect(described_class.sync_with_hub).to eq({})
      expect(RestClient).not_to have_received(:post)
    end
  end

  describe '.register_instance' do
    it 'never contacts the hub' do
      allow(RestClient).to receive(:post)
      described_class.register_instance('test', 'test', 'test@test.com')
      expect(RestClient).not_to have_received(:post)
    end
  end

  describe '.emit_event' do
    it 'never contacts the hub' do
      allow(RestClient).to receive(:post)
      described_class.emit_event('sample_event', { 'sample_data' => 'sample_data' })
      expect(RestClient).not_to have_received(:post)
    end
  end
end
