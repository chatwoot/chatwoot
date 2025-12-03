require 'rails_helper'

RSpec.describe Captain::Providers::GeminiProvider do
  let(:config) do
    {
      provider: 'gemini',
      api_key: 'gemini-test-key',
      endpoint: 'https://generativelanguage.googleapis.com',
      chat_model: 'gemini-2.5-flash',
      embedding_model: 'text-embedding-004'
    }
  end

  let(:provider) { described_class.new(config) }
  let(:mock_client) { double('Gemini') }

  before do
    allow(Gemini).to receive(:new).and_return(mock_client)
  end

  describe '#initialize' do
    it 'initializes Gemini client with correct configuration' do
      expect(Gemini).to receive(:new).with(
        credentials: {
          service: 'generative-language-api',
          api_key: 'gemini-test-key'
        },
        options: {
          model: 'gemini-2.5-flash',
          server_sent_events: true
        }
      )

      described_class.new(config)
    end
  end

  describe '#chat' do
    let(:messages) { [{ role: 'user', content: 'Hello' }] }
    let(:model) { 'gemini-2.5-flash' }
    let(:mock_response) do
      [{
        'candidates' => [
          { 'content' => { 'parts' => [{ 'text' => 'Hi there!' }] } }
        ]
      }]
    end

    it 'makes chat completion request with Gemini format' do
      expected_params = {
        model: 'models/gemini-2.5-flash',
        contents: [
          { role: 'user', parts: [{ text: 'Hello' }] }
        ]
      }

      expect(mock_client).to receive(:stream_generate_content).with(expected_params).and_return(mock_response)

      result = provider.chat(messages: messages, model: model)
      expect(result[:choices][0][:message][:content]).to eq('Hi there!')
    end

    it 'converts assistant role to model role' do
      messages_with_assistant = [
        { role: 'user', content: 'Hello' },
        { role: 'assistant', content: 'Hi' }
      ]

      expect(mock_client).to receive(:stream_generate_content) do |params|
        expect(params[:contents][0][:role]).to eq('user')
        expect(params[:contents][1][:role]).to eq('model')
        mock_response
      end

      provider.chat(messages: messages_with_assistant, model: model)
    end

    it 'includes temperature in generation_config when provided' do
      expect(mock_client).to receive(:stream_generate_content) do |params|
        expect(params[:generation_config][:temperature]).to eq(0.7)
        mock_response
      end

      provider.chat(messages: messages, model: model, temperature: 0.7)
    end

    it 'includes max_tokens as max_output_tokens when provided' do
      expect(mock_client).to receive(:stream_generate_content) do |params|
        expect(params[:generation_config][:max_output_tokens]).to eq(1000)
        mock_response
      end

      provider.chat(messages: messages, model: model, max_tokens: 1000)
    end

    it 'handles errors gracefully' do
      allow(mock_client).to receive(:stream_generate_content).and_raise(StandardError.new('API Error'))

      result = provider.chat(messages: messages, model: model)
      expect(result).to eq({ error: 'API Error' })
    end
  end

  describe '#embeddings' do
    let(:input) { 'Test text' }
    let(:model) { 'text-embedding-004' }
    let(:mock_response) do
      {
        'embedding' => {
          'values' => [0.1, 0.2, 0.3]
        }
      }
    end

    it 'makes embeddings request with Gemini format' do
      expected_params = {
        model: 'models/text-embedding-004',
        content: { parts: [{ text: 'Test text' }] }
      }

      expect(mock_client).to receive(:embed_content).with(expected_params).and_return(mock_response)

      result = provider.embeddings(input: input, model: model)
      expect(result[:data][0][:embedding]).to eq([0.1, 0.2, 0.3])
    end

    it 'handles errors gracefully' do
      allow(mock_client).to receive(:embed_content).and_raise(StandardError.new('API Error'))

      result = provider.embeddings(input: input, model: model)
      expect(result).to eq({ error: 'API Error' })
    end
  end

  describe '#transcribe' do
    let(:file) { double('file', read: 'audio data') }
    let(:model) { 'gemini-2.5-flash' }
    let(:mock_response) do
      {
        'candidates' => [
          { 'content' => { 'parts' => [{ 'text' => 'Transcribed text' }] } }
        ]
      }
    end

    it 'makes transcription request with audio data' do
      expect(mock_client).to receive(:generate_content) do |params|
        expect(params[:model]).to eq('models/gemini-2.5-flash')
        expect(params[:contents][:parts][0][:inline_data][:mime_type]).to eq('audio/wav')
        mock_response
      end

      result = provider.transcribe(file: file, model: model)
      expect(result[:text]).to eq('Transcribed text')
    end

    it 'handles errors gracefully' do
      allow(mock_client).to receive(:generate_content).and_raise(StandardError.new('API Error'))

      result = provider.transcribe(file: file, model: model)
      expect(result).to eq({ error: 'API Error' })
    end
  end

  describe '#upload_file' do
    let(:file) { double('file', content_type: 'application/pdf', original_filename: 'test.pdf') }
    let(:purpose) { 'assistants' }
    let(:mock_response) do
      {
        'file' => { 'name' => 'files/abc123' }
      }
    end

    it 'makes file upload request' do
      expect(mock_client).to receive(:upload_file) do |params|
        expect(params[:file][:data]).to eq(file)
        expect(params[:display_name]).to eq('test.pdf')
        mock_response
      end

      result = provider.upload_file(file: file, purpose: purpose)
      expect(result[:file][:id]).to eq('files/abc123')
    end

    it 'handles errors gracefully' do
      allow(mock_client).to receive(:upload_file).and_raise(StandardError.new('API Error'))

      result = provider.upload_file(file: file, purpose: purpose)
      expect(result).to eq({ error: 'API Error' })
    end
  end
end
