require 'rails_helper'

RSpec.describe Llm::OpenAiConfig do
  describe '.api_key' do
    it 'uses the OpenAI-only key' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'provider-key')
      set_installation_config('CAPTAIN_EMBEDDING_API_KEY', 'openai-key')

      expect(described_class.api_key).to eq('openai-key')
    end

    it 'falls back to the Captain LLM key when OpenAI uses the default endpoint' do
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

      expect(described_class.api_key).to be_blank
    end
  end

  describe '.embedding_model' do
    it 'returns the configured embedding model' do
      set_installation_config('CAPTAIN_EMBEDDING_MODEL', 'text-embedding-3-large')

      expect(described_class.embedding_model).to eq('text-embedding-3-large')
    end

    it 'falls back to the default embedding model' do
      set_installation_config('CAPTAIN_EMBEDDING_MODEL', '')

      expect(described_class.embedding_model).to eq(LlmConstants::DEFAULT_EMBEDDING_MODEL)
    end
  end
end
