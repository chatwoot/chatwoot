require 'rails_helper'

RSpec.describe Llm::ProviderModels do
  let(:models_url) { 'https://api.anthropic.com/v1/models?limit=1000' }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:models_response) do
    {
      data: [
        { type: 'model', id: 'claude-sonnet-5-5', display_name: 'Claude Sonnet 5.5', created_at: '2026-09-01T00:00:00Z' },
        { type: 'model', id: 'claude-haiku-5-5', display_name: 'Claude Haiku 5.5', created_at: '2026-10-01T00:00:00Z' }
      ],
      has_more: false,
      first_id: 'claude-haiku-5-5',
      last_id: 'claude-sonnet-5-5'
    }.to_json
  end

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_ANTHROPIC_API_KEY').update!(value: 'anthropic-key')
  end

  describe '.all' do
    it 'lists the chat models Anthropic offers for the installation key, newest first' do
      stub_request(:get, models_url)
        .with(headers: { 'x-api-key' => 'anthropic-key' })
        .to_return(status: 200, body: models_response, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.all).to eq(
        [
          { 'id' => 'claude-haiku-5-5', 'display_name' => 'Claude Haiku 5.5', 'provider' => 'anthropic' },
          { 'id' => 'claude-sonnet-5-5', 'display_name' => 'Claude Sonnet 5.5', 'provider' => 'anthropic' }
        ]
      )
    end

    it 'reuses the cached list until the key changes' do
      request = stub_request(:get, models_url)
                .to_return(status: 200, body: models_response, headers: { 'Content-Type' => 'application/json' })

      described_class.all
      described_class.all
      expect(request).to have_been_made.once

      InstallationConfig.find_by(name: 'CAPTAIN_ANTHROPIC_API_KEY').update!(value: 'rotated-key')
      described_class.all
      expect(request).to have_been_made.twice
    end

    it 'returns no models and waits before retrying when the provider rejects the key' do
      request = stub_request(:get, models_url)
                .to_return(status: 401, body: { type: 'error', error: { type: 'authentication_error', message: 'invalid x-api-key' } }.to_json,
                           headers: { 'Content-Type' => 'application/json' })

      expect(described_class.all).to eq([])
      expect(described_class.all).to eq([])
      expect(request).to have_been_made.once

      travel_to(6.minutes.from_now) do
        described_class.all
        expect(request).to have_been_made.twice
      end
    end

    it 'returns no models without an Anthropic key' do
      InstallationConfig.find_by(name: 'CAPTAIN_ANTHROPIC_API_KEY').update!(value: '')

      expect(described_class.all).to eq([])
    end

    it 'keeps Chatwoot Cloud on the curated model list' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)

      expect(described_class.all).to eq([])
    end
  end
end
