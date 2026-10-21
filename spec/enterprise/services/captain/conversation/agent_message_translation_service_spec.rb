require 'rails_helper'

RSpec.describe Captain::Conversation::AgentMessageTranslationService do
  let(:account) { create(:account, settings: { auto_translate: true }) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'fr' }) }
  let(:message) do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, sender: user, content: 'Hello there',
                     content_attributes: { translation_pending: true })
  end
  let(:llm_response) { { message: 'Bonjour' } }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, language: nil) }

  before do
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
  end

  it 'stores the reply in the contact language and keeps the typed text under the agent locale' do
    user.update!(ui_settings: { locale: 'en' })

    described_class.new(message: message).perform

    expect(message.reload.content).to eq('Bonjour')
    expect(message.content_attributes).to eq(
      'translations' => { 'en' => 'Hello there' }, 'source_language' => 'fr', 'translation_provider' => 'captain'
    )
  end

  it 'keys the typed text by the language it was written in' do
    allow(detection).to receive(:language).and_return('pt_BR')

    described_class.new(message: message).perform

    expect(message.reload.translations).to eq('pt_BR' => 'Hello there')
  end

  it 'translates a template and keeps the original under the account locale' do
    template = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template, content: 'Hello there',
                                content_attributes: { translation_pending: true })

    described_class.new(message: template).perform

    expect(template.reload.content).to eq('Bonjour')
    expect(template.translations).to eq('en' => 'Hello there')
  end

  it 'detects the conversation language from the contact message the first time a reply needs it' do
    fresh = create(:conversation, account: account, inbox: inbox)
    create(:message, account: account, inbox: inbox, conversation: fresh, message_type: :incoming, content: 'Hola')
    greeting = create(:message, account: account, inbox: inbox, conversation: fresh, message_type: :template, content: 'Hello there',
                                content_attributes: { translation_pending: true })
    allow(detection).to receive(:language).and_return('es', nil)
    allow(llm_service).to receive(:perform).and_return(message: 'Hola')

    described_class.new(message: greeting).perform

    expect(fresh.reload.language).to eq('es')
    expect(greeting.reload.content).to eq('Hola')
    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(target_language: 'es'))
  end

  it 'follows the contact when they switch language midway' do
    switched = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Hallo')
    allow(detection).to receive(:language).and_return('de', nil)
    allow(llm_service).to receive(:perform).and_return(message: 'Guten Tag')

    described_class.new(message: message).perform

    expect(switched.reload.content_attributes['source_language']).to eq('de')
    expect(conversation.reload.language).to eq('de')
    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(target_language: 'de'))
  end

  it 'keeps the conversation language when the latest contact message is a call' do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour',
                     content_attributes: { source_language: 'fr' })
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'WhatsApp Call',
                     content_type: :voice_call)

    described_class.new(message: message).perform

    expect(conversation.reload.language).to eq('fr')
    expect(Captain::Llm::LanguageDetectionService).to have_received(:new).once
  end

  it 'does not detect a contact message again' do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour',
                     content_attributes: { source_language: 'fr' })

    described_class.new(message: message).perform

    expect(Captain::Llm::LanguageDetectionService).to have_received(:new).once
  end

  it 'sends a reply already written in the contact language without calling the translator' do
    allow(detection).to receive(:language).and_return('fr')

    described_class.new(message: message).perform

    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    expect(message.reload.content).to eq('Hello there')
    expect(message.content_attributes).to eq({})
  end

  it 'translates only the reply above the quoted history of an email and keeps the agent text as html' do
    email_inbox = create(:inbox, account: account, channel: create(:channel_email, account: account))
    email_conversation = create(:conversation, account: account, inbox: email_inbox, additional_attributes: { 'conversation_language' => 'fr' })
    email = create(:message, account: account, inbox: email_inbox, conversation: email_conversation, message_type: :outgoing, sender: user,
                             content: "Hello there\n\n> On Monday, Camille wrote:\n> Bonjour",
                             content_attributes: { translation_pending: true, email: { subject: 'Re: Commande' } })

    described_class.new(message: email).perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(text: 'Hello there'))
    expect(email.reload.content).to eq("Bonjour\n\n> On Monday, Camille wrote:\n> Bonjour")
    expect(email.translations.values.first).to include('<p>Hello there</p>').and include('<blockquote>')
    expect(email.content_attributes.dig('email', 'html_content', 'reply')).to include('<p>Bonjour</p>').and include('<blockquote>')
  end

  it 'stores the rendered email html as plain strings so the update can be broadcast' do
    email_inbox = create(:inbox, account: account, channel: create(:channel_email, account: account))
    email_conversation = create(:conversation, account: account, inbox: email_inbox, additional_attributes: { 'conversation_language' => 'fr' })
    email = create(:message, account: account, inbox: email_inbox, conversation: email_conversation, message_type: :outgoing, sender: user,
                             content: 'Hello there', content_attributes: { translation_pending: true, email: { subject: 'Re: Commande' } })

    described_class.new(message: email).perform

    broadcast_attributes = email.previous_changes['content_attributes'].last
    expect(broadcast_attributes['translations'].values.first).to be_an_instance_of(String)
    expect(broadcast_attributes.dig('email', 'html_content', 'full')).to be_an_instance_of(String)
  end

  it 'translates a template in an email inbox, which has no email html to rebuild' do
    email_inbox = create(:inbox, account: account, channel: create(:channel_email, account: account))
    email_conversation = create(:conversation, account: account, inbox: email_inbox, additional_attributes: { 'conversation_language' => 'fr' })
    template = create(:message, account: account, inbox: email_inbox, conversation: email_conversation, message_type: :template,
                                content: 'Hello there', content_attributes: { translation_pending: true })

    described_class.new(message: template).perform

    expect(template.reload.content).to eq('Bonjour')
    expect(template.translations).to eq('en' => 'Hello there')
    expect(template.content_attributes['email']).to be_nil
  end

  it 'sends the reply as written and flags it when the translator fails' do
    allow(llm_service).to receive(:perform).and_return(error: 'quota')

    described_class.new(message: message).perform

    expect(message.reload.content).to eq('Hello there')
    expect(message.content_attributes).to eq('translation_failed' => true)
  end

  it 'flags a reply the translator hands back unchanged although it is in another language' do
    allow(llm_service).to receive(:perform).and_return(message: 'Hello there')
    allow(detection).to receive(:language).and_return('en')

    described_class.new(message: message).perform

    expect(message.reload.content_attributes).to eq('translation_failed' => true)
  end
end
