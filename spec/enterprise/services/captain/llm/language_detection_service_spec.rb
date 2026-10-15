require 'rails_helper'

RSpec.describe Captain::Llm::LanguageDetectionService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account, text: "Hi, it is on it's way!") }

  before do
    InstallationConfig.where(name: 'CAPTAIN_OPEN_AI_API_KEY').destroy_all
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
  end

  it 'asks the model for the language code of the text' do
    expect(service).to receive(:make_api_call) do |args|
      expect(args[:feature]).to eq('language_detection')
      expect(args[:schema]).to eq(Captain::Llm::LanguageDetectionSchema)
      expect(args[:messages].last[:content]).to eq("Hi, it is on it's way!")
      { message: { 'language' => 'en' } }
    end

    expect(service.perform).to eq('en')
  end

  it 'returns nothing when the model cannot tell' do
    allow(service).to receive(:make_api_call).and_return(message: { 'language' => 'und' })

    expect(service.perform).to be_nil
  end

  it 'returns nothing when the model call fails' do
    allow(service).to receive(:make_api_call).and_return(error: 'You are out of Copilot credits.', error_code: 429)

    expect(service.perform).to be_nil
  end

  it 'skips a greeting or a thank-you without a model call' do
    service = described_class.new(account: account, text: 'Gracias')
    allow(service).to receive(:make_api_call)

    expect(service.perform).to be_nil
    expect(service).not_to have_received(:make_api_call)
  end

  it 'asks the model to answer without reasoning' do
    Llm::Config.with_api_key('test-key') do |context|
      chat = service.send(:build_chat, context, model: 'gpt-5-nano', messages: [])

      expect(chat.thinking).to eq(effort: :minimal)
    end
  end
end
