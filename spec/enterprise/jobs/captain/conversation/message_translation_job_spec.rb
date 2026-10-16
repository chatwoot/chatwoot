require 'rails_helper'

RSpec.describe Captain::Conversation::MessageTranslationJob do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'en' }) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour') }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: { message: 'Hello' }) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, language: 'fr') }

  before do
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
  end

  it 'detects the language, stores the translation next to the ones other agents made and follows the contact' do
    message.update!(translations: { 'de' => 'Hallo' })

    described_class.perform_now(message, 'en')

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(text: 'Bonjour', target_language: 'en'))
    expect(message.reload).to have_attributes(source_language: 'fr', translations: { 'de' => 'Hallo', 'en' => 'Hello' })
    expect(conversation.reload.language).to eq('fr')
  end

  it 'keeps the text of a message already in the target language without calling the translator' do
    allow(detection).to receive(:language).and_return('en')

    described_class.perform_now(message, 'en')

    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    expect(message.reload.translations).to eq('en' => 'Bonjour')
  end

  it 'does not detect a message again' do
    message.update!(source_language: 'fr')

    described_class.perform_now(message, 'en')

    expect(Captain::Llm::LanguageDetectionService).not_to have_received(:new)
  end

  it 'leaves the conversation language alone for an older message' do
    older = message
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Thanks')

    described_class.perform_now(older, 'en')

    expect(conversation.reload.language).to eq('en')
  end

  it 'keeps changes made to the message while the translator was running' do
    allow(llm_service).to receive(:perform) do
      message.update!(content_attributes: message.content_attributes.merge('deleted' => true))
      { message: 'Hello' }
    end

    described_class.perform_now(message, 'en')

    expect(message.reload.content_attributes).to include('deleted' => true, 'translations' => { 'en' => 'Hello' })
  end

  it 'marks the message when the translator fails and clears the mark once a translation lands' do
    allow(llm_service).to receive(:perform).and_return({ error: 'quota' }, { message: 'Hello' })

    described_class.perform_now(message, 'en')
    expect(message.reload).to have_attributes(translations: nil, translation_failed: true)

    described_class.perform_now(message, 'en')
    expect(message.reload).to have_attributes(translations: { 'en' => 'Hello' }, translation_failed: nil)
  end
end
