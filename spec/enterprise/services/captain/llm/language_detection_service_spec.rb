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

  it 'asks the model for the language code of the text and hands the response back' do
    allow(service).to receive(:make_api_call).and_return(message: { 'language' => 'en' })

    expect(service.perform).to eq(message: { 'language' => 'en' })
    expect(service.language).to eq('en')
    expect(service).to have_received(:make_api_call).with(
      hash_including(feature: 'language_detection', schema: Captain::Llm::LanguageDetectionSchema,
                     messages: array_including(hash_including(role: 'user', content: "Hi, it is on it's way!")))
    ).twice
  end

  it 'returns no language when the model cannot tell or the call fails' do
    allow(service).to receive(:make_api_call).and_return(message: { 'language' => 'und' })
    expect(service.language).to be_nil

    allow(service).to receive(:make_api_call).and_return(error: 'You are out of Copilot credits.', error_code: 429)
    expect(service.language).to be_nil
  end

  it 'does not debit Captain responses' do
    allow(service).to receive(:make_api_call).and_return(message: { 'language' => 'en' })
    allow(account).to receive(:increment_response_usage)

    service.perform

    expect(account).not_to have_received(:increment_response_usage)
  end
end
