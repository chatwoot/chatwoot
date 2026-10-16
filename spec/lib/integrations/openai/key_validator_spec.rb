require 'rails_helper'

RSpec.describe Integrations::Openai::KeyValidator do
  let(:api_key) { 'sk-test-valid-key-123456789' }
  let(:probe_url) { 'https://api.openai.com/v1/models' }

  it 'accepts keys that OpenAI recognizes' do
    stub_request(:get, probe_url).to_return(status: 200)
    expect(described_class.valid?(api_key)).to be true
  end

  it 'rejects keys that OpenAI does not recognize' do
    stub_request(:get, probe_url).to_return(status: 401)
    expect(described_class.valid?(api_key)).to be false
  end

  it 'rejects blank keys without making a network call' do
    expect(described_class.valid?(nil)).to be false
    expect(described_class.valid?('')).to be false
  end

  it 'treats transient failures as valid to avoid blocking saves' do
    stub_request(:get, probe_url).to_return(status: 500)
    expect(described_class.valid?(api_key)).to be true

    stub_request(:get, probe_url).to_timeout
    expect(described_class.valid?(api_key)).to be true
  end

  it 'routes the probe through the configured endpoint' do
    custom_url = 'https://proxy.example.com/v1/models'
    allow(InstallationConfig).to receive(:find_by).with(name: 'CAPTAIN_OPEN_AI_ENDPOINT')
                                                  .and_return(instance_double(InstallationConfig, value: 'https://proxy.example.com/'))
    stub_request(:get, custom_url).to_return(status: 200)

    described_class.valid?(api_key)

    expect(WebMock).to have_requested(:get, custom_url)
    expect(WebMock).not_to have_requested(:get, probe_url)
  end
end
