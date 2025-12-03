require 'rails_helper'

RSpec.describe Captain::Service do
  let(:config) do
    {
      provider: 'openai',
      api_key: 'test-key',
      endpoint: 'https://api.openai.com',
      chat_model: 'gpt-4o-mini'
    }
  end

  describe '#initialize' do
    it 'raises NotImplementedError for abstract base class' do
      expect { described_class.new(config) }.to raise_error(NotImplementedError, /must implement #initialize_client/)
    end
  end

  describe 'abstract methods' do
    let(:service) { described_class.allocate }

    before do
      service.instance_variable_set(:@config, config)
      service.instance_variable_set(:@client, instance_double(OpenAI::Client))
    end

    it 'raises NotImplementedError for #chat' do
      expect { service.chat(messages: [], model: 'test') }.to raise_error(
        NotImplementedError, /must implement #chat/
      )
    end

    it 'raises NotImplementedError for #embeddings' do
      expect { service.embeddings(input: 'test', model: 'test') }.to raise_error(
        NotImplementedError, /must implement #embeddings/
      )
    end

    it 'raises NotImplementedError for #transcribe' do
      expect { service.transcribe(file: instance_double(File), model: 'test') }.to raise_error(
        NotImplementedError, /must implement #transcribe/
      )
    end

    it 'raises NotImplementedError for #upload_file' do
      expect { service.upload_file(file: instance_double(File), purpose: 'test') }.to raise_error(
        NotImplementedError, /must implement #upload_file/
      )
    end
  end
end
