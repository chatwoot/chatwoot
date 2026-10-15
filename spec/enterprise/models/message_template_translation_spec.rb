require 'rails_helper'

RSpec.describe Message do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'fr' }) }
  let(:llm_response) { { message: [{ 'id' => 0, 'text' => 'Bonjour ! Comment pouvons-nous vous aider ?' }] } }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, perform: nil) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    account.enable_features('auto_translate', 'captain_tasks')
    account.save!
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
  end

  it 'sends template messages in the contact language and keeps the original for agents' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template,
                               content: 'Hi there! How can we help you today?')

    expect(message.content).to eq('Bonjour ! Comment pouvons-nous vous aider ?')
    expect(message.processed_message_content).to eq('Bonjour ! Comment pouvons-nous vous aider ?')
    expect(message.translations).to eq('en' => 'Hi there! How can we help you today?')
  end

  it 'leaves the template untouched when the translator fails' do
    allow(llm_service).to receive(:perform).and_return(error: 'LLM timeout')
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template,
                               content: 'Hi there! How can we help you today?')

    expect(message.content).to eq('Hi there! How can we help you today?')
    expect(message.translations).to be_nil
  end

  it 'does not create the template when Captain is not configured' do
    allow(llm_service).to receive(:perform).and_raise(StandardError, 'Captain AI API key is not configured.')

    expect { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template, content: 'Hi there!') }
      .to raise_error(StandardError, 'Captain AI API key is not configured.')
  end

  it 'translates a template written in another language than the account' do
    allow(detection).to receive(:perform).and_return('es')
    conversation.update!(additional_attributes: { 'conversation_language' => 'en' })
    allow(llm_service).to receive(:perform).and_return(message: [{ 'id' => 0, 'text' => 'Hello! How can we help you today?' }])
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template,
                               content: '¡Hola! Gracias por escribirnos. Nuestro equipo te responderá lo antes posible.')

    expect(message.content).to eq('Hello! How can we help you today?')
    expect(message.translations).to eq('es' => '¡Hola! Gracias por escribirnos. Nuestro equipo te responderá lo antes posible.')
  end

  it 'skips templates when the contact already writes the account language' do
    conversation.update!(additional_attributes: { 'conversation_language' => 'en' })
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template, content: 'Hi there!')

    expect(message.content).to eq('Hi there!')
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'skips incoming and outgoing messages' do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour')

    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end
end
