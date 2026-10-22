require 'rails_helper'

RSpec.describe Llm::TextToSpeechService do
  let(:account) { create(:account) }
  let(:text) { 'Please call during business hours.' }
  let(:service) { described_class.new(text: text, account: account) }

  before do
    InstallationConfig.find_or_create_by!(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-api-key' }
  end

  it 'uses the announcement model and consumes one response after successful generation' do
    request = stub_request(:post, 'https://api.openai.com/v1/audio/speech')
              .with(body: { model: 'gpt-4o-mini-tts-2025-12-15', input: text, voice: 'alloy', response_format: 'mp3' }.to_json)
              .to_return(status: 200, body: 'generated audio', headers: { 'Content-Type' => 'audio/mpeg' })
    expect(account).to receive(:increment_response_usage).once

    expect(service.perform).to eq('generated audio')
    expect(request).to have_been_requested.once
  end

  it 'does not consume a response when audio generation fails' do
    stub_request(:post, 'https://api.openai.com/v1/audio/speech').to_return(status: 500)
    expect(account).not_to receive(:increment_response_usage)

    expect { service.perform }.to(raise_error { |error| expect(error.class.name).to eq('Faraday::ServerError') })
  end

  it 'requires Captain and available response credits' do
    account.disable_features!('captain_integration')
    expect(described_class.available_for?(account)).to be(false)

    account.enable_features!('captain_integration')
    allow(account).to receive(:usage_limits).and_return(captain: { responses: { current_available: 0 } })
    expect(described_class.available_for?(account)).to be(false)

    allow(account).to receive(:usage_limits).and_return(captain: { responses: { current_available: 1 } })
    expect(described_class.available_for?(account)).to be(true)
  end
end
