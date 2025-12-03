require 'rails_helper'

RSpec.describe Captain::Providers::OpenaiProvider do
  let(:config) do
    {
      provider: 'openai',
      api_key: 'sk-test-key',
      endpoint: 'https://api.openai.com',
      chat_model: 'gpt-4o-mini',
      embedding_model: 'text-embedding-3-small',
      transcription_model: 'whisper-1'
    }
  end

  let(:provider) { described_class.new(config) }
  let(:mock_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_client)
  end

  describe '#initialize' do
    it 'initializes OpenAI client with correct configuration' do
      expect(OpenAI::Client).to receive(:new).with(
        access_token: 'sk-test-key',
        uri_base: 'https://api.openai.com',
        log_errors: false
      )

      described_class.new(config)
    end
  end

  describe '#chat' do
    let(:messages) { [{ role: 'user', content: 'Hello' }] }
    let(:model) { 'gpt-4o-mini' }
    let(:mock_response) do
      {
        'choices' => [
          { 'message' => { 'content' => 'Hi there!' } }
        ]
      }
    end

    it 'makes chat completion request with basic parameters' do
      expect(mock_client).to receive(:chat).with(
        parameters: {
          model: model,
          messages: messages
        }
      ).and_return(mock_response)

      result = provider.chat(messages: messages, model: model)
      expect(result).to eq(mock_response)
    end

    it 'includes tools when provided' do
      tools = [{ type: 'function', function: { name: 'test' } }]

      expect(mock_client).to receive(:chat).with(
        parameters: hash_including(
          model: model,
          messages: messages,
          tools: tools
        )
      ).and_return(mock_response)

      provider.chat(messages: messages, model: model, tools: tools)
    end

    it 'includes response_format when provided' do
      response_format = { type: 'json_object' }

      expect(mock_client).to receive(:chat).with(
        parameters: hash_including(
          response_format: response_format
        )
      ).and_return(mock_response)

      provider.chat(messages: messages, model: model, response_format: response_format)
    end

    it 'includes temperature when provided' do
      expect(mock_client).to receive(:chat).with(
        parameters: hash_including(
          temperature: 0.7
        )
      ).and_return(mock_response)

      provider.chat(messages: messages, model: model, temperature: 0.7)
    end

    it 'handles errors gracefully' do
      allow(mock_client).to receive(:chat).and_raise(StandardError.new('API Error'))

      result = provider.chat(messages: messages, model: model)
      expect(result).to eq({ error: 'API Error' })
    end
  end

  describe '#embeddings' do
    let(:input) { 'Test text' }
    let(:model) { 'text-embedding-3-small' }
    let(:mock_response) do
      {
        'data' => [
          { 'embedding' => [0.1, 0.2, 0.3] }
        ]
      }
    end

    it 'makes embeddings request' do
      expect(mock_client).to receive(:embeddings).with(
        parameters: {
          model: model,
          input: input
        }
      ).and_return(mock_response)

      result = provider.embeddings(input: input, model: model)
      expect(result).to eq(mock_response)
    end

    it 'handles errors gracefully' do
      allow(mock_client).to receive(:embeddings).and_raise(StandardError.new('API Error'))

      result = provider.embeddings(input: input, model: model)
      expect(result).to eq({ error: 'API Error' })
    end
  end

  describe '#transcribe' do
    let(:file) { double('file') }
    let(:model) { 'whisper-1' }
    let(:mock_audio) { instance_double('OpenAI::Audio') }
    let(:mock_response) { { 'text' => 'Transcribed text' } }

    before do
      allow(mock_client).to receive(:audio).and_return(mock_audio)
    end

    it 'makes transcription request' do
      expect(mock_audio).to receive(:transcribe).with(
        parameters: {
          model: model,
          file: file
        }
      ).and_return(mock_response)

      result = provider.transcribe(file: file, model: model)
      expect(result).to eq(mock_response)
    end

    it 'handles errors gracefully' do
      allow(mock_audio).to receive(:transcribe).and_raise(StandardError.new('API Error'))

      result = provider.transcribe(file: file, model: model)
      expect(result).to eq({ error: 'API Error' })
    end
  end

  describe '#upload_file' do
    let(:file) { double('file') }
    let(:purpose) { 'assistants' }
    let(:mock_files) { instance_double('OpenAI::Files') }
    let(:mock_response) { { 'id' => 'file-123' } }

    before do
      allow(mock_client).to receive(:files).and_return(mock_files)
    end

    it 'makes file upload request' do
      expect(mock_files).to receive(:upload).with(
        parameters: {
          file: file,
          purpose: purpose
        }
      ).and_return(mock_response)

      result = provider.upload_file(file: file, purpose: purpose)
      expect(result).to eq(mock_response)
    end

    it 'handles errors gracefully' do
      allow(mock_files).to receive(:upload).and_raise(StandardError.new('API Error'))

      result = provider.upload_file(file: file, purpose: purpose)
      expect(result).to eq({ error: 'API Error' })
    end
  end
end
