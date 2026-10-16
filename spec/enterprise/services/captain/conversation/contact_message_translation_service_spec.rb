require 'rails_helper'

RSpec.describe Captain::Conversation::ContactMessageTranslationService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'en' }) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour') }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: { message: ['Hello'] }) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, language: 'fr') }

  before do
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
  end

  it 'detects the language, stores the translation next to the ones other agents made and follows the contact' do
    message.update!(translations: { 'de' => 'Hallo' })

    described_class.new(message: message, target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(texts: ['Bonjour'], target_language: 'en'))
    expect(message.reload).to have_attributes(source_language: 'fr', translations: { 'de' => 'Hallo', 'en' => 'Hello' })
    expect(conversation.reload.language).to eq('fr')
  end

  it 'keeps the text of a message already in the target language without calling the translator' do
    allow(detection).to receive(:language).and_return('en')

    described_class.new(message: message, target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    expect(message.reload.translations).to eq('en' => 'Bonjour')
  end

  it 'does not detect a message again' do
    message.update!(source_language: 'fr')

    described_class.new(message: message, target_language: 'en').perform

    expect(Captain::Llm::LanguageDetectionService).not_to have_received(:new)
  end

  it 'translates the text nodes of an html email and keeps its markup, leaving the quoted history as it is' do
    html = '<div dir="ltr"><p>Bonjour <b>Camille</b></p></div><blockquote class="gmail_quote"><p>Hello</p></blockquote>'
    email = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                             content: "Bonjour Camille\n\n> Hello", content_attributes: { email: { html_content: { full: html } } })
    allow(llm_service).to receive(:perform).and_return(message: %w[Hello Camille])

    described_class.new(message: email, target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(texts: %w[Bonjour Camille]))
    expect(email.reload.translations['en'])
      .to include('<p>Hello <b>Camille</b></p>').and include('<blockquote class="gmail_quote"><p>Hello</p></blockquote>')
  end

  it 'leaves the conversation language alone for an older message' do
    older = message
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Thanks')

    described_class.new(message: older, target_language: 'en').perform

    expect(conversation.reload.language).to eq('en')
  end

  it 'keeps a translation another job saved while the translator was running' do
    allow(llm_service).to receive(:perform) do
      message.reload.update!(translations: { 'de' => 'Hallo' })
      { message: ['Hello'] }
    end

    described_class.new(message: message, target_language: 'en').perform

    expect(message.reload.translations).to eq('de' => 'Hallo', 'en' => 'Hello')
  end

  it 'does not store a translation on a message deleted while the translator was running' do
    allow(llm_service).to receive(:perform) do
      message.reload.update!(content: 'This message was deleted', content_attributes: { deleted: true })
      { message: ['Hello'] }
    end

    described_class.new(message: message, target_language: 'en').perform

    expect(message.reload.content_attributes).to eq('deleted' => true)
  end

  it 'marks the message when the translator fails and clears the mark once a translation lands' do
    allow(llm_service).to receive(:perform).and_return({ error: 'quota' }, { message: ['Hello'] })

    described_class.new(message: message, target_language: 'en').perform
    expect(message.reload).to have_attributes(translations: nil, translation_failed: true)

    described_class.new(message: message, target_language: 'en').perform
    expect(message.reload).to have_attributes(translations: { 'en' => 'Hello' }, translation_failed: nil)
  end
end
