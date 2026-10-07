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
end
