require 'rails_helper'

RSpec.describe Captain::Llm::ArticleTranslationService do
  let(:account) { create(:account) }
  let(:target_language) { 'Spanish' }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  describe '#perform with type: :title' do
    let(:service) do
      described_class.new(account: account, text: 'Getting Started', target_language: target_language, type: :title)
    end

    it 'returns the stripped translated title' do
      expect(service).to receive(:make_api_call) do |args|
        expect(args[:messages][0][:content]).to include('professional translator')
        expect(args[:messages][0][:content]).to include(target_language)
        expect(args[:messages][1][:content]).to eq('Getting Started')
        { message: "  Primeros pasos  \n" }
      end

      expect(service.perform).to include(message: 'Primeros pasos')
    end
  end

  describe '#perform with type: :content' do
    let(:content) { "# Welcome\nSome markdown." }
    let(:service) do
      described_class.new(account: account, text: content, target_language: target_language, type: :content)
    end

    it 'returns the stripped translated content using the markdown system prompt' do
      expect(service).to receive(:make_api_call) do |args|
        expect(args[:messages][0][:content]).to include('markdown')
        expect(args[:messages][0][:content]).to include('Preserve ALL HTML tags')
        expect(args[:messages][1][:content]).to eq(content)
        { message: "# Bienvenido\nAlgo de markdown.\n" }
      end

      expect(service.perform).to include(message: "# Bienvenido\nAlgo de markdown.")
    end
  end

  describe '#perform with an invalid type' do
    it 'raises ArgumentError' do
      service = described_class.new(account: account, text: 'hi', target_language: target_language, type: :invalid)

      expect { service.perform }.to raise_error(ArgumentError, /Invalid type/)
    end
  end

  describe '#perform when the API call fails' do
    let(:service) do
      described_class.new(account: account, text: 'Getting Started', target_language: target_language, type: :title)
    end

    it 'returns the error hash unchanged' do
      allow(service).to receive(:make_api_call).and_return(error: 'LLM timeout', error_code: 500)

      expect(service.perform).to eq(error: 'LLM timeout', error_code: 500)
    end
  end
end
