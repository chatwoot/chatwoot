require 'rails_helper'

RSpec.describe Captain::Llm::MessageTranslationService do
  let(:account) { create(:account) }
  let(:texts) { ['Bonjour', 'Merci **beaucoup**'] }
  let(:service) { described_class.new(account: account, texts: texts, target_language: 'pt_BR') }

  before do
    InstallationConfig.where(name: 'CAPTAIN_OPEN_AI_API_KEY').destroy_all
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  it 'asks for one translation per text into the named language and returns them in order' do
    expect(service).to receive(:make_api_call) do |args|
      expect(args[:feature]).to eq('message_translation')
      expect(args[:schema]).to eq(Captain::Llm::MessageTranslationSchema)
      expect(args[:messages][0][:content]).to include('Portuguese (Brazil)')
      expect(args[:messages][1][:content]).to eq(texts.to_json)
      { message: { 'translations' => ['Olá', 'Muito **obrigado**'] } }
    end

    expect(service.perform).to include(message: ['Olá', 'Muito **obrigado**'])
  end

  it 'strips control characters the model slips into a translation' do
    allow(service).to receive(:make_api_call).and_return(message: { 'translations' => ["Ol\u0000á\u0016!--\nmundo", 'ok'] })

    expect(service.perform[:message].first).to eq("Olá!--\nmundo")
  end

  it 'names the target by its raw code when the language map does not know it' do
    service = described_class.new(account: account, texts: texts, target_language: 'zz')
    expect(service).to receive(:make_api_call) do |args|
      expect(args[:messages][0][:content]).to include('into zz')
      { message: { 'translations' => [] } }
    end

    service.perform
  end
end
