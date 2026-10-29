require 'rails_helper'

RSpec.describe Llm::TextToSpeechService do
  let(:account) { create(:account) }
  let(:text) { 'Please call during business hours.' }
  let(:service) { described_class.new(text: text, account: account) }

  before do
    InstallationConfig.find_or_create_by!(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-api-key' }
  end

  it 'uses the announcement model and consumes one response after successful generation' do
    request = stub_request(:post, 'https://api.openai.com/v1/chat/completions')
              .with(body: {
                model: 'gpt-audio-1.5', modalities: %w[text audio], audio: { voice: 'alloy', format: 'mp3' },
                messages: [{ role: 'system', content: described_class::INSTRUCTIONS }, { role: 'user', content: text }]
              }.to_json)
              .to_return(status: 200, body: {
                choices: [{ message: { audio: { data: Base64.strict_encode64('generated audio'), transcript: "  #{text}\n" } } }]
              }.to_json, headers: { 'Content-Type' => 'application/json' })
    expect(account).to receive(:increment_response_usage).once

    expect(service.perform).to eq('generated audio')
    expect(request).to have_been_requested.once
  end

  it 'does not consume a response when audio generation fails' do
    stub_request(:post, 'https://api.openai.com/v1/chat/completions').to_return(status: 500)
    expect(account).not_to receive(:increment_response_usage)

    expect { service.perform }.to(raise_error { |error| expect(error.class.name).to eq('Faraday::ServerError') })
  end

  ['Please call.', nil].each do |transcript|
    it "rejects a #{transcript.nil? ? 'missing' : 'mismatched'} transcript without consuming a response" do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 200, body: {
          choices: [{ message: { audio: { data: Base64.strict_encode64('generated audio'), transcript: transcript } } }]
        }.to_json, headers: { 'Content-Type' => 'application/json' })
      expect(account).not_to receive(:increment_response_usage)

      expect { service.perform }.to(raise_error do |error|
        expect(error.class.name).to eq('CustomExceptions::InvalidAnnouncementAudio')
      end)
    end
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
