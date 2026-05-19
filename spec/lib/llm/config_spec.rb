require 'rails_helper'

RSpec.describe Llm::Config do
  describe '.default_openai_endpoint?' do
    it 'returns true when OpenAI provider uses the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.openai.com')

      expect(described_class.default_openai_endpoint?).to be true
    end

    it 'returns true when OpenAI provider uses the default endpoint with /v1' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.openai.com/v1')

      expect(described_class.default_openai_endpoint?).to be true
    end

    it 'returns false when OpenAI provider uses a custom endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://example.com/v1')

      expect(described_class.default_openai_endpoint?).to be false
    end

    it 'returns false for other providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')

      expect(described_class.default_openai_endpoint?).to be false
    end
  end

  describe '.configure_provider' do
    it 'ignores provider settings unsupported by the target config object' do
      config = Class.new do
        attr_accessor :openai_api_key
      end.new

      expect do
        described_class.configure_provider(config, provider: 'openai', api_key: 'test-key', api_base: 'https://example.com')
      end.not_to raise_error

      expect(config.openai_api_key).to eq('test-key')
    end
  end
end
