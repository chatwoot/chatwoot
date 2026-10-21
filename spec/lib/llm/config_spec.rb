require 'rails_helper'

RSpec.describe Llm::Config do
  describe '.configure_ruby_llm' do
    it 'adds the API version to the configured OpenAI endpoint' do
      original_base = RubyLLM.config.openai_api_base
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://example.test/')

      described_class.send(:configure_ruby_llm)

      expect(RubyLLM.config.openai_api_base).to eq('https://example.test/v1')
    ensure
      RubyLLM.configure { |config| config.openai_api_base = original_base }
    end

    it 'does not duplicate the API version when the endpoint already includes it' do
      original_base = RubyLLM.config.openai_api_base
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://example.test/v1/')

      described_class.send(:configure_ruby_llm)

      expect(RubyLLM.config.openai_api_base).to eq('https://example.test/v1')
    ensure
      RubyLLM.configure { |config| config.openai_api_base = original_base }
    end
  end

  describe '.openai_api_base' do
    it 'defaults to the OpenAI API when no endpoint is configured' do
      expect(described_class.openai_api_base).to eq('https://api.openai.com/v1')
    end

    it 'adds the API version to an endpoint without it' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://example.test')

      expect(described_class.openai_api_base).to eq('https://example.test/v1')
    end

    it 'keeps a single API version when the endpoint already includes it' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://example.test/v1')

      expect(described_class.openai_api_base).to eq('https://example.test/v1')
    end
  end
end
