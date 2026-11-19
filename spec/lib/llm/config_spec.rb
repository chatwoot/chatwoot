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
  end

  describe '.with_api_key' do
    it 'builds an Anthropic context with the given key' do
      described_class.with_api_key('anthropic-key', provider: 'anthropic') do |context|
        expect(context.config.anthropic_api_key).to eq('anthropic-key')
      end
    end
  end

  describe '.api_key_for' do
    it 'reads the installation key for each supported provider' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_ANTHROPIC_API_KEY').update!(value: 'anthropic-key')

      expect(described_class.api_key_for('anthropic')).to eq('anthropic-key')
      expect(described_class.api_key_for('gemini')).to be_nil
    end
  end
end
