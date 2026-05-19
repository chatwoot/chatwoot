require 'rails_helper'

RSpec.describe Llm::OpenAiConfig do
  describe '.api_key' do
    it 'uses the OpenAI-only key before the Captain LLM key' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'provider-key')
      set_installation_config('CAPTAIN_EMBEDDING_API_KEY', 'openai-key')

      expect(described_class.api_key).to eq('openai-key')
    end

    it 'falls back to the Captain LLM key only when OpenAI uses the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.openai.com/v1')
      set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'openai-key')
      set_installation_config('CAPTAIN_EMBEDDING_API_KEY', '')

      expect(described_class.api_key).to eq('openai-key')
    end

    it 'does not use the Captain LLM key when OpenAI uses a custom endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://example.com/v1')
      set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'provider-key')
      set_installation_config('CAPTAIN_EMBEDDING_API_KEY', '')

      expect(described_class.api_key).to be_nil
    end
  end
end
