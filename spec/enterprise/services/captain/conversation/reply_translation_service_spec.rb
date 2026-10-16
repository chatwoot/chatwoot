require 'rails_helper'

RSpec.describe Captain::Conversation::ReplyTranslationService do
  let(:account) { create(:account, settings: { auto_translate: true }) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'fr' }) }
  let(:message) do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, sender: user, content: 'Hello there')
  end
  let(:llm_response) { { message: ['Bonjour'] } }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, language: nil) }

  before do
    account.enable_features('auto_translate', 'captain_tasks')
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
  end

  it 'stores the reply in the contact language and keeps the typed text under the agent locale' do
    user.update!(ui_settings: { locale: 'en' })

    described_class.new(message: message).perform

    expect(message.reload.content).to eq('Bonjour')
    expect(message.content_attributes).to include('translations' => { 'en' => 'Hello there' }, 'source_language' => 'fr')
    expect(message.content_attributes).not_to have_key('translation_pending')
  end

  it 'keys the typed text by the language it was written in' do
    allow(detection).to receive(:language).and_return('pt_BR')

    described_class.new(message: message).perform

    expect(message.reload.translations).to eq('pt_BR' => 'Hello there')
  end

  it 'leaves a reply already written in the contact language as it is' do
    allow(llm_service).to receive(:perform).and_return(message: ['Hello there'])

    described_class.new(message: message).perform

    expect(message.reload.content).to eq('Hello there')
    expect(message.content_attributes).to eq({})
  end

  it 'translates only the reply above the quoted history of an email and keeps the agent text as html' do
    email_inbox = create(:inbox, account: account, channel: create(:channel_email, account: account))
    email_conversation = create(:conversation, account: account, inbox: email_inbox, additional_attributes: { 'conversation_language' => 'fr' })
    email = create(:message, account: account, inbox: email_inbox, conversation: email_conversation, message_type: :outgoing, sender: user,
                             content: "Hello there\n\n> On Monday, Camille wrote:\n> Bonjour",
                             content_attributes: { email: { subject: 'Re: Commande' } })

    described_class.new(message: email).perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(texts: ['Hello there']))
    expect(email.reload.content).to eq("Bonjour\n\n> On Monday, Camille wrote:\n> Bonjour")
    expect(email.translations.values.first).to include('<p>Hello there</p>').and include('<blockquote>')
    expect(email.content_attributes.dig('email', 'html_content', 'reply')).to include('<p>Bonjour</p>').and include('<blockquote>')
  end

  it 'sends the reply as written and flags it when the translator fails' do
    allow(llm_service).to receive(:perform).and_return(error: 'quota')

    described_class.new(message: message).perform

    expect(message.reload.content).to eq('Hello there')
    expect(message.content_attributes).to eq('translation_failed' => true)
  end

  it 'flags a reply the translator hands back unchanged although it is in another language' do
    allow(llm_service).to receive(:perform).and_return(message: ['Hello there'])
    allow(detection).to receive(:language).and_return('en')

    described_class.new(message: message).perform

    expect(message.reload.content_attributes).to eq('translation_failed' => true)
  end
end
