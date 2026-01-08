# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::ElevenlabsClient, type: :service do
  let(:api_key) { 'test-api-key' }
  let(:client) { described_class.new(api_key: api_key) }
  let(:voice_id) { 'EXAVITQu4vr4xnSDxMaL' }

  describe '#initialize' do
    it 'raises error when API key is blank' do
      # Ensure no fallback sources provide a key
      allow(Current).to receive(:account).and_return(nil)
      allow(InstallationConfig).to receive(:find_by).and_return(nil)

      with_modified_env ELEVENLABS_API_KEY: nil do
        expect { described_class.new(api_key: nil) }.to raise_error(
          Aloo::ElevenlabsClient::AuthenticationError,
          'ElevenLabs API key not configured'
        )
      end
    end

    it 'accepts valid API key' do
      expect { described_class.new(api_key: 'valid-key') }.not_to raise_error
    end

    context 'when API key is from environment' do
      it 'uses environment variable as fallback' do
        allow(Current).to receive(:account).and_return(nil)
        allow(InstallationConfig).to receive(:find_by).and_return(nil)

        with_modified_env ELEVENLABS_API_KEY: 'env-api-key' do
          client = described_class.new
          expect(client).to be_a(described_class)
        end
      end
    end
  end

  describe '#text_to_speech' do
    let(:audio_binary) { 'fake-audio-binary-data' }

    before do
      stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
        .with(
          headers: {
            'xi-api-key' => api_key,
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: audio_binary)
    end

    it 'returns audio binary data' do
      result = client.text_to_speech(text: 'Hello world', voice_id: voice_id)
      expect(result).to eq(audio_binary)
    end

    it 'sends correct request body' do
      stub = stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
             .with(
               body: hash_including(
                 text: 'Hello world',
                 model_id: 'eleven_multilingual_v2'
               )
             )
             .to_return(status: 200, body: audio_binary)

      client.text_to_speech(text: 'Hello world', voice_id: voice_id)
      expect(stub).to have_been_requested
    end

    it 'includes voice settings when provided' do
      stub = stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
             .with(
               body: hash_including(
                 voice_settings: {
                   stability: 0.7,
                   similarity_boost: 0.8
                 }
               )
             )
             .to_return(status: 200, body: audio_binary)

      client.text_to_speech(
        text: 'Hello',
        voice_id: voice_id,
        voice_settings: { stability: 0.7, similarity_boost: 0.8 }
      )
      expect(stub).to have_been_requested
    end

    context 'with validation errors' do
      it 'raises error for blank text' do
        expect { client.text_to_speech(text: '', voice_id: voice_id) }
          .to raise_error(Aloo::ElevenlabsClient::Error, 'Text cannot be blank')
      end

      it 'raises error for text exceeding max length' do
        long_text = 'a' * 5001
        expect { client.text_to_speech(text: long_text, voice_id: voice_id) }
          .to raise_error(Aloo::ElevenlabsClient::Error, 'Text exceeds maximum length (5000 characters)')
      end
    end

    context 'with API errors' do
      it 'raises AuthenticationError for 401' do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .to_return(status: 401, body: '{"detail": "Invalid API key"}')

        expect { client.text_to_speech(text: 'Hello', voice_id: voice_id) }
          .to raise_error(Aloo::ElevenlabsClient::AuthenticationError)
      end

      it 'raises RateLimitError for 429' do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .to_return(status: 429, body: '{"detail": "Rate limit exceeded"}')

        expect { client.text_to_speech(text: 'Hello', voice_id: voice_id) }
          .to raise_error(Aloo::ElevenlabsClient::RateLimitError)
      end

      it 'raises InvalidVoiceError for 422' do
        stub_request(:post, "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}")
          .to_return(status: 422, body: '{"detail": "Invalid voice ID"}')

        expect { client.text_to_speech(text: 'Hello', voice_id: voice_id) }
          .to raise_error(Aloo::ElevenlabsClient::InvalidVoiceError)
      end
    end
  end

  describe '#list_voices' do
    let(:voices_response) do
      {
        'voices' => [
          { 'voice_id' => 'voice1', 'name' => 'Sarah', 'category' => 'premade' },
          { 'voice_id' => 'voice2', 'name' => 'Adam', 'category' => 'premade' }
        ]
      }
    end

    before do
      stub_request(:get, 'https://api.elevenlabs.io/v1/voices')
        .with(headers: { 'xi-api-key' => api_key })
        .to_return(status: 200, body: voices_response.to_json)
    end

    it 'returns array of voices' do
      voices = client.list_voices
      expect(voices).to be_an(Array)
      expect(voices.length).to eq(2)
    end

    it 'returns voice data with expected structure' do
      voices = client.list_voices
      expect(voices.first).to include('voice_id', 'name', 'category')
    end
  end

  describe '#get_voice' do
    let(:voice_response) do
      {
        'voice_id' => voice_id,
        'name' => 'Sarah',
        'category' => 'premade',
        'labels' => { 'accent' => 'american' }
      }
    end

    before do
      stub_request(:get, "https://api.elevenlabs.io/v1/voices/#{voice_id}")
        .with(headers: { 'xi-api-key' => api_key })
        .to_return(status: 200, body: voice_response.to_json)
    end

    it 'returns voice details' do
      voice = client.get_voice(voice_id)
      expect(voice['voice_id']).to eq(voice_id)
      expect(voice['name']).to eq('Sarah')
    end
  end

  describe '#get_subscription' do
    let(:subscription_response) do
      {
        'tier' => 'starter',
        'character_count' => 5000,
        'character_limit' => 30_000
      }
    end

    before do
      stub_request(:get, 'https://api.elevenlabs.io/v1/user/subscription')
        .with(headers: { 'xi-api-key' => api_key })
        .to_return(status: 200, body: subscription_response.to_json)
    end

    it 'returns subscription info' do
      subscription = client.get_subscription
      expect(subscription['tier']).to eq('starter')
      expect(subscription['character_limit']).to eq(30_000)
    end
  end

  describe '#list_models' do
    let(:models_response) do
      [
        { 'model_id' => 'eleven_multilingual_v2', 'name' => 'Multilingual v2' },
        { 'model_id' => 'eleven_turbo_v2', 'name' => 'Turbo v2' }
      ]
    end

    before do
      stub_request(:get, 'https://api.elevenlabs.io/v1/models')
        .with(headers: { 'xi-api-key' => api_key })
        .to_return(status: 200, body: models_response.to_json)
    end

    it 'returns array of models' do
      models = client.list_models
      expect(models).to be_an(Array)
      expect(models.length).to eq(2)
    end
  end
end
