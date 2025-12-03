require 'rails_helper'

RSpec.describe Captain::Providers::Factory do
  describe '.create' do
    context 'with OpenAI provider' do
      let(:config) do
        {
          provider: 'openai',
          api_key: 'sk-test-key',
          endpoint: 'https://api.openai.com',
          chat_model: 'gpt-4o-mini'
        }
      end

      it 'creates OpenaiProvider instance' do
        provider = described_class.create(config)
        expect(provider).to be_a(Captain::Providers::OpenaiProvider)
      end

      it 'passes config to provider' do
        provider = described_class.create(config)
        expect(provider.config).to eq(config)
      end
    end

    context 'with Gemini provider' do
      let(:config) do
        {
          provider: 'gemini',
          api_key: 'gemini-test-key',
          endpoint: 'https://generativelanguage.googleapis.com',
          chat_model: 'gemini-2.5-flash'
        }
      end

      it 'creates GeminiProvider instance' do
        provider = described_class.create(config)
        expect(provider).to be_a(Captain::Providers::GeminiProvider)
      end

      it 'passes config to provider' do
        provider = described_class.create(config)
        expect(provider.config).to eq(config)
      end
    end

    context 'with unknown provider' do
      let(:config) do
        {
          provider: 'unknown',
          api_key: 'test-key'
        }
      end

      it 'raises ArgumentError' do
        expect { described_class.create(config) }.to raise_error(
          ArgumentError, /Unknown provider: unknown/
        )
      end
    end

    context 'without config parameter' do
      before do
        create(:installation_config, name: 'CAPTAIN_LLM_PROVIDER', value: 'openai')
        create(:installation_config, name: 'CAPTAIN_LLM_API_KEY', value: 'sk-test-key')
      end

      it 'uses Captain::Config.current_config' do
        provider = described_class.create
        expect(provider).to be_a(Captain::Providers::OpenaiProvider)
      end

      it 'creates provider with current config' do
        provider = described_class.create
        expect(provider.config[:provider]).to eq('openai')
        expect(provider.config[:api_key]).to eq('sk-test-key')
      end
    end
  end
end
