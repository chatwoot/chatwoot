require 'rails_helper'

RSpec.describe Widget::AudioTranscriptionConfig do
  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'captain-api-key')
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_ENDPOINT', value: 'https://captain.example.com')
  end

  it 'uses the Captain key and endpoint together as fallback configuration' do
    with_modified_env(WIDGET_TRANSCRIPTION_OPENAI_API_KEY: nil, WIDGET_TRANSCRIPTION_OPENAI_ENDPOINT: nil) do
      expect(described_class.api_key).to eq('captain-api-key')
      expect(described_class.endpoint).to eq('https://captain.example.com/')
    end
  end

  it 'does not send the Captain key to a widget-specific endpoint' do
    with_modified_env(WIDGET_TRANSCRIPTION_OPENAI_API_KEY: nil, WIDGET_TRANSCRIPTION_OPENAI_ENDPOINT: 'https://transcribe.example.com') do
      expect(described_class.api_key).to be_nil
      expect(described_class).not_to be_configured
    end
  end

  it 'uses the default endpoint with a widget-specific key' do
    with_modified_env(WIDGET_TRANSCRIPTION_OPENAI_API_KEY: 'widget-api-key', WIDGET_TRANSCRIPTION_OPENAI_ENDPOINT: nil) do
      expect(described_class.endpoint).to eq(described_class::DEFAULT_ENDPOINT)
    end
  end

  it 'uses the routed audio transcription model by default' do
    with_modified_env(WIDGET_TRANSCRIPTION_OPENAI_MODEL: nil) do
      expect(described_class.model(create(:account))).to eq(Llm::Models.default_model_for('audio_transcription'))
    end
  end

  it 'prefers an explicit model for self-hosted OpenAI-compatible servers' do
    with_modified_env(WIDGET_TRANSCRIPTION_OPENAI_MODEL: 'whisper-1') do
      expect(described_class.model(create(:account))).to eq('whisper-1')
    end
  end
end
