require 'rails_helper'

RSpec.describe Captain::Config do
  let(:installation_config) { class_double(InstallationConfig).as_stubbed_const }
  let(:config_record) { instance_double(InstallationConfig, value: 'openai') }

  before do
    described_class.reset_provider_cache!
  end

  describe '.current_provider' do
    it 'returns the configured provider' do
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_PROVIDER').and_return(config_record)
      expect(described_class.current_provider).to eq('openai')
    end

    it 'returns nil if no provider is configured' do
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_PROVIDER').and_return(nil)
      expect(described_class.current_provider).to be_nil
    end
  end

  describe '.defaults_for' do
    it 'returns OpenAI defaults for openai provider' do
      expect(described_class.defaults_for('openai')).to eq(Captain::Config::OPENAI)
    end

    it 'returns Gemini defaults for gemini provider' do
      expect(described_class.defaults_for('gemini')).to eq(Captain::Config::GEMINI)
    end

    it 'raises error for unknown provider' do
      expect { described_class.defaults_for('unknown') }.to raise_error(ArgumentError)
    end
  end

  describe '.config_for' do
    let(:api_key_record) { instance_double(InstallationConfig, value: 'test-key') }

    before do
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_API_KEY').and_return(api_key_record)
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_ENDPOINT').and_return(nil)
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_MODEL').and_return(nil)
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_EMBEDDING_MODEL').and_return(nil)
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_TRANSCRIPTION_MODEL').and_return(nil)
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_FIRECRAWL_API_KEY').and_return(nil)
    end

    it 'returns complete configuration with defaults' do
      config = described_class.config_for('openai')

      expect(config[:provider]).to eq('openai')
      expect(config[:api_key]).to eq('test-key')
      expect(config[:endpoint]).to eq(Captain::Config::OPENAI[:endpoint])
      expect(config[:chat_model]).to eq(Captain::Config::OPENAI[:chat_model])
    end

    it 'overrides defaults with user config' do
      endpoint_record = instance_double(InstallationConfig, value: 'custom-endpoint')
      allow(installation_config).to receive(:find_by).with(name: 'CAPTAIN_LLM_ENDPOINT').and_return(endpoint_record)

      config = described_class.config_for('openai')
      expect(config[:endpoint]).to eq('custom-endpoint')
    end
  end
end
