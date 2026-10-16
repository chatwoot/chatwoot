require 'rails_helper'

RSpec.describe Captain::Conversation::AutoTranslateService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:greeting) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour') }
  let(:thanks) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Merci') }
  let(:english) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'ok thanks') }
  let(:reply) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, content: 'Hi') }
  let(:llm_response) { { message: ['Hello', 'Thank you', 'ok thanks'] } }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, language: nil) }
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
      texts: ['Bonjour', 'Merci', 'ok thanks']
    )
  end

  it 'stores translations and keeps the own text of messages already in the target language' do
    expect(service.perform).to contain_exactly(greeting, thanks, english)
    expect(greeting.reload.translations).to eq('en' => 'Hello')
    expect(english.reload.translations).to eq('en' => 'ok thanks')
  end

  it 'translates bot replies, which are written in the contact language, but not agent replies' do
    bot_reply = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing,
                                 sender: create(:agent_bot, account: account), content: 'Bonjour, comment puis-je vous aider ?')
    allow(llm_service).to receive(:perform).and_return(message: ['Hello, how can I help you?'])

    described_class.new(conversation: conversation, message_ids: [bot_reply.id, reply.id], target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService)
      .to have_received(:new).with(hash_including(texts: ['Bonjour, comment puis-je vous aider ?']))
    expect(bot_reply.reload.translations).to eq('en' => 'Hello, how can I help you?')
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

  it 'returns a message above the size limit as settled without translating it' do
    long_message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'a' * 20_001)
    allow(llm_service).to receive(:perform).and_return(message: ['Hello'])

    settled = described_class.new(conversation: conversation, message_ids: [long_message.id, greeting.id], target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(texts: ['Bonjour']))
    expect(settled).to contain_exactly(greeting, long_message)
    expect(long_message.reload.translations).to be_nil
  end

  it 'leaves an email with an html body alone' do
    email = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour Camille',
                             content_attributes: { email: { html_content: { full: '<p>Bonjour <b>Camille</b></p>' } } })

    expect(described_class.new(conversation: conversation, message_ids: [email.id], target_language: 'en').perform).to eq([])
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'detects the contact language from the batch when the conversation has none' do
    allow(detection).to receive(:language).and_return('fr')
    question = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                                content: 'Celui-ci met quatre secondes à charger.')
    allow(llm_service).to receive(:perform).and_return(message: ['This one takes four seconds to load.'])

    described_class.new(conversation: conversation, message_ids: [question.id], target_language: 'en').perform

    expect(conversation.reload.language).to eq('fr')
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
    allow(llm_service).to receive(:perform).and_return(message: Array.new(20, 'Hi'))

    described_class.new(conversation: conversation, message_ids: messages.map(&:id), target_language: 'en').perform

    expect(Captain::Llm::MessageTranslationService).to have_received(:new) do |args|
      expect(args[:texts].size).to eq(20)
    end
  end

  it 'raises when the translator returns fewer translations than messages' do
    allow(llm_service).to receive(:perform).and_return(message: ['Hello'])

    expect { service.perform }.to raise_error(StandardError, 'Captain returned an incomplete translation.')
  end

  it 'raises with the Captain error when the translator fails' do
    allow(llm_service).to receive(:perform).and_return(error: 'Captain AI is disabled for this account.')

    expect { service.perform }.to raise_error(StandardError, 'Captain AI is disabled for this account.')
  end
end
