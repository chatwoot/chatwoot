require 'rails_helper'

RSpec.describe Captain::Llm::MessageTranslationService do
  let(:account) { create(:account) }
  let(:texts) { [{ id: 1, content: 'Bonjour' }, { id: 2, content: 'Merci **beaucoup**' }] }
  let(:service) { described_class.new(account: account, texts: texts, target_language: 'pt_BR') }

  before do
    InstallationConfig.where(name: 'CAPTAIN_OPEN_AI_API_KEY').destroy_all
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  it 'asks for structured translations into the named language and returns the items' do
    expect(service).to receive(:make_api_call) do |args|
      expect(args[:feature]).to eq('message_translation')
      expect(args[:schema]).to eq(Captain::Llm::MessageTranslationSchema)
      expect(args[:messages][0][:content]).to include('Portuguese (Brazil)')
      expect(args[:messages][1][:content]).to eq(texts.to_json)
      { message: { 'messages' => [{ 'id' => 1, 'text' => 'Olá' }] } }
    end

    expect(service.perform).to include(message: [{ 'id' => 1, 'text' => 'Olá' }])
  end

  it 'strips control characters the model slips into a translation' do
    allow(service).to receive(:make_api_call).and_return(message: { 'messages' => [{ 'id' => '1', 'text' => "Ol\u0000á\u0016!--\nmundo" }] })

    expect(service.perform[:message].first['text']).to eq("Olá!--\nmundo")
  end

  it 'names the target by its raw code when the language map does not know it' do
    service = described_class.new(account: account, texts: texts, target_language: 'zz')
    expect(service).to receive(:make_api_call) do |args|
      expect(args[:messages][0][:content]).to include('into zz')
      { message: { 'messages' => [] } }
    end

    service.perform
  end

  it 'returns the error hash unchanged when the API call fails' do
    allow(service).to receive(:make_api_call).and_return(error: 'LLM timeout', error_code: 500)

    expect(service.perform).to eq(error: 'LLM timeout', error_code: 500)
  end
end
