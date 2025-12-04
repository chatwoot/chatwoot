# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Providers::OpenaiProvider do
  let(:provider) { described_class.new }
  let(:mock_client) { instance_double(OpenAI::Client) }

  before do
    allow(Captain::Config).to receive(:current_provider).and_return('openai')
    allow(Captain::Config).to receive(:config_for).and_return({
                                                                api_key: 'test-api-key',
                                                                endpoint: 'https://api.openai.com',
                                                                chat_model: 'gpt-4',
                                                                embedding_model: 'text-embedding-3-small'
                                                              })
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
  end

  describe '#chat' do
    it 'calls the OpenAI chat API with correct parameters' do
      parameters = {
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello' }],
        temperature: 0.7
      }

      expected_response = {
        'choices' => [
          {
            'message' => {
              'content' => 'Hi there!',
              'role' => 'assistant'
            }
          }
        ]
      }

      expect(mock_client).to receive(:chat).with(parameters: parameters).and_return(expected_response)

      result = provider.chat(parameters: parameters)
      expect(result).to eq(expected_response)
    end

    it 'handles errors from OpenAI API' do
      parameters = {
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello' }]
      }

      error_response = {
        'error' => {
          'message' => 'Invalid API key'
        }
      }

      expect(mock_client).to receive(:chat).and_return(error_response)

      expect { provider.chat(parameters: parameters) }.to raise_error(StandardError, /OpenAI API Error/)
    end
  end

  describe '#embeddings' do
    it 'calls the OpenAI embeddings API with correct parameters' do
      parameters = {
        model: 'text-embedding-3-small',
        input: 'Test text'
      }

      expected_response = {
        'data' => [
          {
            'embedding' => [0.1, 0.2, 0.3]
          }
        ]
      }

      expect(mock_client).to receive(:embeddings).with(parameters: parameters).and_return(expected_response)

      result = provider.embeddings(parameters: parameters)
      expect(result).to eq(expected_response)
    end

    it 'handles errors from OpenAI embeddings API' do
      parameters = {
        model: 'text-embedding-3-small',
        input: 'Test text'
      }

      error_response = {
        'error' => {
          'message' => 'Rate limit exceeded'
        }
      }

      expect(mock_client).to receive(:embeddings).and_return(error_response)

      expect { provider.embeddings(parameters: parameters) }.to raise_error(StandardError, /OpenAI API Error/)
    end
  end

  describe '#transcribe' do
    let(:audio_file) { instance_double(File, path: '/tmp/audio.mp3') }
    let(:mock_audio) { instance_double(OpenAI::Audio) }

    before do
      allow(mock_client).to receive(:audio).and_return(mock_audio)
    end

    it 'calls the OpenAI transcription API with correct parameters' do
      parameters = {
        model: 'whisper-1',
        file: audio_file,
        temperature: 0.4
      }

      expected_response = {
        'text' => 'This is the transcribed text'
      }

      expect(mock_audio).to receive(:transcribe).with(parameters: parameters).and_return(expected_response)

      result = provider.transcribe(parameters: parameters)
      expect(result).to eq(expected_response)
    end

    it 'handles errors from OpenAI transcription API' do
      parameters = {
        model: 'whisper-1',
        file: audio_file
      }

      error_response = {
        'error' => {
          'message' => 'Unsupported audio format'
        }
      }

      expect(mock_audio).to receive(:transcribe).and_return(error_response)

      expect { provider.transcribe(parameters: parameters) }.to raise_error(StandardError, /OpenAI API Error/)
    end
  end

  describe '#upload_file' do
    let(:pdf_file) { instance_double(File, path: '/tmp/document.pdf') }
    let(:mock_files) { instance_double(OpenAI::Files) }

    before do
      allow(mock_client).to receive(:files).and_return(mock_files)
    end

    it 'calls the OpenAI file upload API with correct parameters' do
      parameters = {
        file: pdf_file,
        purpose: 'assistants'
      }

      expected_response = {
        'id' => 'file-abc123'
      }

      expect(mock_files).to receive(:upload).with(parameters: parameters).and_return(expected_response)

      result = provider.upload_file(parameters: parameters)
      expect(result).to eq(expected_response)
    end

    it 'handles errors from OpenAI file upload API' do
      parameters = {
        file: pdf_file,
        purpose: 'assistants'
      }

      error_response = {
        'error' => {
          'message' => 'File too large'
        }
      }

      expect(mock_files).to receive(:upload).and_return(error_response)

      expect { provider.upload_file(parameters: parameters) }.to raise_error(StandardError, /OpenAI API Error/)
    end
  end
end
