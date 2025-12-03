require 'rails_helper'

RSpec.describe Captain::Config do
  describe '.current_provider' do
    it 'returns the configured provider' do
      create(:installation_config, name: 'CAPTAIN_LLM_PROVIDER', value: 'openai')
      expect(described_class.current_provider).to eq('openai')
    end

    it 'caches the provider' do
      create(:installation_config, name: 'CAPTAIN_LLM_PROVIDER', value: 'openai')
      described_class.current_provider

      expect(InstallationConfig).not_to receive(:find_by)
      described_class.current_provider
    end
  end

  describe '.reset_provider_cache!' do
    it 'clears the cached provider' do
      create(:installation_config, name: 'CAPTAIN_LLM_PROVIDER', value: 'openai')
      described_class.current_provider

      described_class.reset_provider_cache!

      expect(InstallationConfig).to receive(:find_by).and_call_original
      described_class.current_provider
    end
  end

  describe '.defaults_for' do
    it 'returns OpenAI defaults' do
      defaults = described_class.defaults_for('openai')

      expect(defaults[:endpoint]).to eq('https://api.openai.com')
      expect(defaults[:chat_model]).to eq('gpt-4o-mini')
      expect(defaults[:embedding_model]).to eq('text-embedding-3-small')
    end

    it 'returns Gemini defaults' do
      defaults = described_class.defaults_for('gemini')

      expect(defaults[:endpoint]).to eq('https://generativelanguage.googleapis.com')
      expect(defaults[:chat_model]).to eq('gemini-2.5-flash')
      expect(defaults[:embedding_model]).to eq('text-embedding-004')
    end

    it 'raises error for unknown provider' do
      expect { described_class.defaults_for('unknown') }.to raise_error(ArgumentError)
    end
  end

  describe '.current_config' do
    before do
      create(:installation_config, name: 'CAPTAIN_LLM_PROVIDER', value: 'openai')
      create(:installation_config, name: 'CAPTAIN_LLM_API_KEY', value: 'sk-test-key')
    end

    it 'returns complete configuration for current provider' do
      config = described_class.current_config

      expect(config[:provider]).to eq('openai')
      expect(config[:api_key]).to eq('sk-test-key')
      expect(config[:endpoint]).to eq('https://api.openai.com')
      expect(config[:chat_model]).to eq('gpt-4o-mini')
    end
  end

  describe '.config_for' do
    context 'with only defaults' do
      before do
        create(:installation_config, name: 'CAPTAIN_LLM_API_KEY', value: 'sk-test-key')
      end

      it 'returns configuration with provider and API key' do
        config = described_class.config_for('openai')

        expect(config[:provider]).to eq('openai')
        expect(config[:api_key]).to eq('sk-test-key')
        expect(config[:firecrawl_api_key]).to be_nil
      end

      it 'returns configuration with default model values' do
        config = described_class.config_for('openai')

        expect(config[:endpoint]).to eq('https://api.openai.com')
        expect(config[:chat_model]).to eq('gpt-4o-mini')
        expect(config[:embedding_model]).to eq('text-embedding-3-small')
        expect(config[:transcription_model]).to eq('whisper-1')
        expect(config[:pdf_processing_model]).to eq('gpt-4o-mini')
      end
    end

    context 'with user overrides' do
      before do
        create(:installation_config, name: 'CAPTAIN_LLM_API_KEY', value: 'sk-test-key')
        create(:installation_config, name: 'CAPTAIN_LLM_ENDPOINT', value: 'https://custom.openai.com')
        create(:installation_config, name: 'CAPTAIN_LLM_MODEL', value: 'gpt-4-turbo')
        create(:installation_config, name: 'CAPTAIN_LLM_EMBEDDING_MODEL', value: 'text-embedding-3-large')
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'fc-test-key')
      end

      it 'returns configuration with user overrides' do
        config = described_class.config_for('openai')

        expect(config[:endpoint]).to eq('https://custom.openai.com')
        expect(config[:chat_model]).to eq('gpt-4-turbo')
        expect(config[:embedding_model]).to eq('text-embedding-3-large')
        expect(config[:firecrawl_api_key]).to eq('fc-test-key')
      end
    end

    context 'with Gemini provider' do
      before do
        create(:installation_config, name: 'CAPTAIN_LLM_API_KEY', value: 'gemini-key')
      end

      it 'returns Gemini configuration' do
        config = described_class.config_for('gemini')

        expect(config[:provider]).to eq('gemini')
        expect(config[:api_key]).to eq('gemini-key')
        expect(config[:endpoint]).to eq('https://generativelanguage.googleapis.com')
        expect(config[:chat_model]).to eq('gemini-2.5-flash')
        expect(config[:embedding_model]).to eq('text-embedding-004')
      end
    end

    context 'with empty string overrides' do
      before do
        create(:installation_config, name: 'CAPTAIN_LLM_API_KEY', value: 'sk-test-key')
        create(:installation_config, name: 'CAPTAIN_LLM_MODEL', value: '')
      end

      it 'uses defaults when config value is empty string' do
        config = described_class.config_for('openai')

        expect(config[:chat_model]).to eq('gpt-4o-mini')
      end
    end
  end
end
