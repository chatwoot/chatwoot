require 'rails_helper'

RSpec.describe Captain::Conversation::AutoTranslateService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:greeting) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour') }
  let(:thanks) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Merci') }
  let(:english) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'ok thanks') }
  let(:reply) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, content: 'Hi') }
  let(:llm_response) do
    { message: [
      { 'id' => "#{greeting.id}:0", 'text' => 'Hello' },
      { 'id' => "#{thanks.id}:0", 'text' => 'Thank you' },
      { 'id' => "#{english.id}:0", 'text' => 'ok thanks' }
    ] }
  end
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, perform: nil) }
  let(:service) do
    described_class.new(conversation: conversation, message_ids: [greeting.id, thanks.id, english.id, reply.id], target_language: 'en')
  end

  before do
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
  end

  it 'sends only the incoming messages to the translator' do
    service.perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(
      account: account, target_language: 'en', conversation_display_id: conversation.display_id,
      texts: [
        { id: "#{greeting.id}:0", content: 'Bonjour' }, { id: "#{thanks.id}:0", content: 'Merci' }, { id: "#{english.id}:0", content: 'ok thanks' }
      ]
    )
  end

  it 'stores translations and keeps the own text of messages already in the target language' do
    expect(service.perform).to contain_exactly(greeting, thanks, english)
    expect(greeting.reload.translations).to eq('en' => 'Hello')
    expect(english.reload.translations).to eq('en' => 'ok thanks')
  end

  it 'stores a message already written in the target language without calling the translator' do
    english = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                               content: 'This one takes four seconds to load before it is ready.', content_attributes: { source_language: 'en' })

    described_class.new(conversation: conversation, message_ids: [english.id], target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    expect(english.reload.content_attributes).to include('translations' => { 'en' => english.content }, 'source_language' => 'en')
  end

  it 'keeps changes made to a message while the translator was running' do
    allow(llm_service).to receive(:perform) do
      greeting.update!(content_attributes: greeting.content_attributes.merge('deleted' => true))
      llm_response
    end

    service.perform

    expect(greeting.reload.content_attributes).to include('deleted' => true, 'translations' => { 'en' => 'Hello' })
  end

  it 'leaves messages above the size limit untranslated' do
    long_message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'a' * 20_001)

    described_class.new(conversation: conversation, message_ids: [long_message.id, greeting.id], target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService)
      .to have_received(:new).with(hash_including(texts: [{ id: "#{greeting.id}:0", content: 'Bonjour' }]))
  end

  it 'translates the text nodes of an html email and keeps its markup' do
    html = '<div style="color:red"><p>Bonjour <b>Camille</b></p><blockquote>Ancien message</blockquote></div>'
    email = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour Camille',
                             content_attributes: { email: { html_content: { full: html } } })
    allow(llm_service).to receive(:perform).and_return(message: [
                                                         { 'id' => "#{email.id}:0", 'text' => 'Hello' },
                                                         { 'id' => "#{email.id}:1", 'text' => 'Camille' }
                                                       ])

    described_class.new(conversation: conversation, message_ids: [email.id], target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(
      hash_including(texts: [{ id: "#{email.id}:0", content: 'Bonjour' }, { id: "#{email.id}:1", content: 'Camille' }])
    )
    expect(email.reload.translations['en']).to eq('<div style="color:red"><p>Hello <b>Camille</b></p><blockquote>Ancien message</blockquote></div>')
  end

  it 'detects the contact language from the batch when the conversation has none' do
    allow(detection).to receive(:perform).and_return('fr')
    question = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                                content: 'Celui-ci met quatre secondes à charger.')
    allow(llm_service).to receive(:perform).and_return(message: [{ 'id' => "#{question.id}:0", 'text' => 'This one takes four seconds to load.' }])

    described_class.new(conversation: conversation, message_ids: [question.id], target_language: 'en').perform

    expect(conversation.reload.language).to eq('fr')
  end

  it 'keeps the language a message set while the translator was running' do
    allow(detection).to receive(:perform).and_return('en')
    question = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                                content: 'Celui-ci met quatre secondes à charger.')
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    account.enable_features('auto_translate', 'captain_tasks')
    account.save!
    allow(llm_service).to receive(:perform) do
      create(:message, account: account, inbox: inbox, conversation: Conversation.find(conversation.id), message_type: :incoming,
                       content: 'This one takes four seconds to load before it is ready.')
      { message: [{ 'id' => "#{question.id}:0", 'text' => 'This one takes four seconds to load.' }] }
    end

    described_class.new(conversation: conversation, message_ids: [question.id], target_language: 'en').perform

    expect(conversation.reload.language).to eq('en')
  end

  it 'keeps a language that was detected earlier' do
    conversation.update!(additional_attributes: { 'conversation_language' => 'es' })
    question = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                                content: 'Celui-ci met quatre secondes à charger.')
    allow(llm_service).to receive(:perform).and_return(message: [{ 'id' => "#{question.id}:0", 'text' => 'This one takes four seconds to load.' }])

    described_class.new(conversation: conversation, message_ids: [question.id], target_language: 'en').perform

    expect(conversation.reload.language).to eq('es')
  end

  it 'returns messages another agent already translated without calling the translator again' do
    greeting.update!(translations: { 'en' => 'Hello' })
    thanks.update!(translations: { 'en' => 'Thank you' })
    english.destroy!

    expect(described_class.new(conversation: conversation, message_ids: [greeting.id, thanks.id], target_language: 'en').perform)
      .to contain_exactly(greeting, thanks)
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'translates at most twenty messages per request' do
    messages = create_list(:message, 22, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Salut')
    allow(llm_service).to receive(:perform).and_return(message: [])

    described_class.new(conversation: conversation, message_ids: messages.map(&:id), target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new) do |args|
      expect(args[:texts].size).to eq(20)
    end
  end

  it 'raises with the Captain error when the translator fails' do
    allow(llm_service).to receive(:perform).and_return(error: 'Captain AI is disabled for this account.')

    expect { service.perform }.to raise_error(StandardError, 'Captain AI is disabled for this account.')
  end
end
