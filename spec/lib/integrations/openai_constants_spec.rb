require 'rails_helper'

RSpec.describe Integrations::OpenaiConstants do
  describe '.endpoint' do
    context 'without LEGACY_OPENAI_ENDPOINT configured' do
      before do
        InstallationConfig.find_by(name: 'LEGACY_OPENAI_ENDPOINT')&.destroy
      end

      it 'returns default endpoint' do
        expect(described_class.endpoint).to eq('https://api.openai.com')
      end
    end

    context 'with LEGACY_OPENAI_ENDPOINT configured' do
      before do
        create(:installation_config,
               name: 'LEGACY_OPENAI_ENDPOINT',
               value: 'https://custom.openai.com')
      end

      it 'returns configured endpoint' do
        expect(described_class.endpoint).to eq('https://custom.openai.com')
      end
    end
  end

  describe '.model' do
    context 'without any configuration' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_GPT_MODEL', nil).and_return(nil)
        InstallationConfig.find_by(name: 'LEGACY_OPENAI_MODEL')&.destroy
      end

      it 'returns default model' do
        expect(described_class.model).to eq('gpt-4o-mini')
      end
    end

    context 'with ENV variable set' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_GPT_MODEL', nil).and_return('gpt-4')
      end

      it 'returns ENV model' do
        expect(described_class.model).to eq('gpt-4')
      end
    end

    context 'with LEGACY_OPENAI_MODEL configured and no ENV' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_GPT_MODEL', nil).and_return(nil)
        create(:installation_config,
               name: 'LEGACY_OPENAI_MODEL',
               value: 'gpt-4-turbo')
      end

      it 'returns configured model' do
        expect(described_class.model).to eq('gpt-4-turbo')
      end
    end

    context 'with both ENV and InstallationConfig set' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_GPT_MODEL', nil).and_return('gpt-4-from-env')
        create(:installation_config,
               name: 'LEGACY_OPENAI_MODEL',
               value: 'gpt-4-from-config')
      end

      it 'prioritizes ENV variable' do
        expect(described_class.model).to eq('gpt-4-from-env')
      end
    end
  end
end
