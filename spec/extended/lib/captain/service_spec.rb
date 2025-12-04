# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Service do
  # Create a concrete test class since Service is abstract
  let(:concrete_class) do
    Class.new(described_class) do
      def initialize_client
        @client = 'mock_client'
      end
    end
  end

  before do
    allow(Captain::Config).to receive(:current_provider).and_return('openai')
    allow(Captain::Config).to receive(:config_for).and_return({
                                                                api_key: 'test-key',
                                                                endpoint: 'https://api.test.com',
                                                                chat_model: 'gpt-4'
                                                              })
  end

  describe '#initialize' do
    it 'sets config from Captain::Config' do
      service = concrete_class.new
      expect(service.instance_variable_get(:@config)).to be_a(Hash)
      expect(service.instance_variable_get(:@config)[:api_key]).to eq('test-key')
    end

    it 'calls initialize_client' do
      service = concrete_class.new
      expect(service.instance_variable_get(:@client)).not_to be_nil
    end

    it 'raises NotImplementedError if initialize_client is not implemented' do
      abstract_class = Class.new(described_class)
      expect { abstract_class.new }.to raise_error(NotImplementedError)
    end
  end

  describe '#chat' do
    it 'raises NotImplementedError' do
      service = concrete_class.new
      expect do
        service.chat(parameters: { messages: [], model: 'gpt-4' })
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#embeddings' do
    it 'raises NotImplementedError' do
      service = concrete_class.new
      expect do
        service.embeddings(parameters: { input: 'test', model: 'text-embedding-3' })
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#transcribe' do
    it 'raises NotImplementedError' do
      service = concrete_class.new
      expect do
        service.transcribe(parameters: { file: 'test.mp3', model: 'whisper-1' })
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#upload_file' do
    it 'raises NotImplementedError' do
      service = concrete_class.new
      expect do
        service.upload_file(parameters: { file: 'test.txt', purpose: 'assistants' })
      end.to raise_error(NotImplementedError)
    end
  end
end
