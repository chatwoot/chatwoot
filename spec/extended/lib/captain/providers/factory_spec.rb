require 'rails_helper'

RSpec.describe Captain::Providers::Factory do
  describe '.create' do
    before do
      allow(Captain::Config).to receive(:current_provider).and_return(provider_name)
      # Mock config loading which happens on provider initialization
      allow(Captain::Config).to receive(:current_config).and_return({ api_key: 'test' })
    end

    context 'when provider is openai' do
      let(:provider_name) { 'openai' }

      it 'returns an OpenaiProvider instance' do
        expect(described_class.create).to be_a(Captain::Providers::OpenaiProvider)
      end
    end

    context 'when provider is gemini' do
      let(:provider_name) { 'gemini' }

      it 'returns a GeminiProvider instance' do
        allow(Captain::Config).to receive(:current_provider).and_return('gemini')

        expect(described_class.create).to be_a(Captain::Providers::GeminiProvider)
      end
    end

    context 'when provider is unknown' do
      let(:provider_name) { 'unknown' }

      it 'raises an ArgumentError' do
        expect { described_class.create }.to raise_error(ArgumentError, /Unknown LLM provider/)
      end
    end
  end
end
