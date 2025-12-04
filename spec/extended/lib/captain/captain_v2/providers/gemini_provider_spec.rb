# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Providers::GeminiProvider do
  let(:provider) { described_class.new }

  before do
    allow(Captain::Config).to receive(:current_provider).and_return('gemini')
    allow(Captain::Config).to receive(:config_for).and_return({
                                                                api_key: 'test-gemini-key',
                                                                endpoint: 'https://generativelanguage.googleapis.com',
                                                                chat_model: 'gemini-2.0-flash-exp',
                                                                embedding_model: 'text-embedding-004'
                                                              })
  end

  describe '#chat' do
    it 'raises NotImplementedError (pending implementation)' do
      parameters = {
        model: 'gemini-2.0-flash-exp',
        messages: [{ role: 'user', content: 'Hello' }]
      }

      expect { provider.chat(parameters: parameters) }.to raise_error(NotImplementedError)
    end
  end

  describe '#embeddings' do
    it 'raises NotImplementedError (pending implementation)' do
      parameters = {
        model: 'text-embedding-004',
        input: 'Test text for embedding'
      }

      expect { provider.embeddings(parameters: parameters) }.to raise_error(NotImplementedError)
    end
  end

  describe '#transcribe' do
    let(:audio_file) do
      double('File',
             path: '/tmp/audio.mp3',
             content_type: 'audio/mp3')
    end

    it 'raises NotImplementedError (pending implementation)' do
      parameters = {
        model: 'gemini-2.0-flash-exp',
        file: audio_file
      }

      expect { provider.transcribe(parameters: parameters) }.to raise_error(NotImplementedError)
    end
  end

  describe '#upload_file' do
    let(:pdf_file) do
      double('File',
             path: '/tmp/document.pdf',
             content_type: 'application/pdf',
             original_filename: 'document.pdf')
    end

    it 'raises NotImplementedError (pending implementation)' do
      parameters = {
        file: pdf_file,
        purpose: 'assistants'
      }

      expect { provider.upload_file(parameters: parameters) }.to raise_error(NotImplementedError)
    end
  end
end
