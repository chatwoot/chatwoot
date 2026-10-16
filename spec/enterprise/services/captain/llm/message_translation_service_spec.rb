require 'rails_helper'

RSpec.describe Captain::Llm::MessageTranslationService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account, text: 'Merci **beaucoup**', target_language: 'pt_BR') }

  before do
    InstallationConfig.where(name: 'CAPTAIN_OPEN_AI_API_KEY').destroy_all
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  it 'asks for a translation of the text into the named language' do
    expect(service).to receive(:make_api_call) do |args|
      expect(args[:feature]).to eq('message_translation')
      expect(args[:schema]).to eq(Captain::Llm::MessageTranslationSchema)
      expect(args[:messages][0][:content]).to include('Portuguese (Brazil)')
      expect(args[:messages][1][:content]).to eq('Merci **beaucoup**')
      { message: { 'translation' => 'Muito **obrigado**' } }
    end

    expect(service.perform).to include(message: 'Muito **obrigado**')
  end

  it 'strips control characters the model slips into a translation' do
    allow(service).to receive(:make_api_call).and_return(message: { 'translation' => "Ol\u0000á\u0016!--\nmundo" })

    expect(service.perform[:message]).to eq("Olá!--\nmundo")
  end

  it 'names the target by its raw code when the language map does not know it' do
    service = described_class.new(account: account, text: 'Merci', target_language: 'zz')
    expect(service).to receive(:make_api_call) do |args|
      expect(args[:messages][0][:content]).to include('into zz')
      { message: { 'translation' => 'Merci' } }
    end

    service.perform
  end
end
