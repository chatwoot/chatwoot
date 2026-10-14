require 'rails_helper'

RSpec.describe Messages::MessageBuilder do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'fr' }) }
  let(:params) { ActionController::Parameters.new(content: 'Hello there') }
  let(:llm_response) { { message: [{ 'id' => 0, 'text' => 'Bonjour' }] } }
  let(:llm_service) { instance_double(Captain::Llm::MessageTranslationService, perform: llm_response) }

  before do
    account.enable_features('auto_translate', 'captain_tasks')
    account.save!
    allow(Captain::Llm::MessageTranslationService).to receive(:new).and_return(llm_service)
  end

  it 'sends the reply in the contact language and keeps the typed text under the agent locale' do
    message = described_class.new(user, conversation, params).perform

    expect(message.content).to eq('Bonjour')
    expect(message.translations).to eq('en' => 'Hello there')
    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(
      account: account, texts: [{ id: 0, content: 'Hello there' }], target_language: 'fr', conversation_display_id: conversation.display_id
    )
  end

  it 'keys the typed text by the agent profile language' do
    user.update!(ui_settings: { 'locale' => 'pt_BR' })

    expect(described_class.new(user, conversation, params).perform.translations).to eq('pt_BR' => 'Hello there')
  end

  it 'translates what the agent wrote even when the profile language matches the contact' do
    user.update!(ui_settings: { 'locale' => 'fr' })
    typed = ActionController::Parameters.new(content: 'This one takes four seconds to load before it is ready.')

    message = described_class.new(user, conversation, typed).perform

    expect(message.content).to eq('Bonjour')
    expect(message.translations).to eq('en' => 'This one takes four seconds to load before it is ready.')
  end

  it 'sends a reply already written in the contact language as it is' do
    typed = ActionController::Parameters.new(content: 'Celui-ci met quatre secondes à charger.')

    expect(described_class.new(user, conversation, typed).perform.content).to eq('Celui-ci met quatre secondes à charger.')
    expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
  end

  it 'leaves the message untouched when the translator returns the same text' do
    allow(llm_service).to receive(:perform).and_return(message: [{ 'id' => 0, 'text' => 'Hello there' }])
    message = described_class.new(user, conversation, params).perform

    expect(message.content).to eq('Hello there')
    expect(message.translations).to be_nil
  end

  it 'renders liquid variables before translating and keeps the rendered text as the original' do
    conversation.contact.update!(name: 'Camille')
    allow(llm_service).to receive(:perform).and_return(message: [{ 'id' => 0, 'text' => 'Bonjour Camille' }])
    message = described_class.new(user, conversation, ActionController::Parameters.new(content: 'Hi {{contact.name}}')).perform

    expect(message.content).to eq('Bonjour Camille')
    expect(message.translations).to eq('en' => 'Hi Camille')
    expect(Captain::Llm::MessageTranslationService).to have_received(:new).with(hash_including(texts: [{ id: 0, content: 'Hi Camille' }]))
  end

  it 'blocks the send when Captain is not configured' do
    allow(llm_service).to receive(:perform).and_return(error: 'Captain AI API key is not configured.', error_code: 401)

    expect { described_class.new(user, conversation, params).perform }
      .to raise_error(StandardError, 'Captain AI API key is not configured.')
  end

  it 'sends the reply as written when the translator fails' do
    allow(llm_service).to receive(:perform).and_return(error: 'You are out of Copilot credits.', error_code: 429)
    message = described_class.new(user, conversation, params).perform

    expect(message.content).to eq('Hello there')
    expect(message.translations).to be_nil
  end

  it 'sends the reply as written when the translator returns nothing' do
    allow(llm_service).to receive(:perform).and_return(message: [])

    expect(described_class.new(user, conversation, params).perform.content).to eq('Hello there')
  end

  describe 'messages that are never translated' do
    let(:agent_bot) { create(:agent_bot, account: account) }

    it 'skips when the feature is off' do
      account.disable_features('auto_translate')
      account.save!

      expect(described_class.new(user, conversation, params).perform.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips private notes' do
      message = described_class.new(user, conversation, ActionController::Parameters.new(content: 'Hello there', private: true)).perform

      expect(message.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips when the contact language is unknown' do
      conversation.update!(additional_attributes: {})

      expect(described_class.new(user, conversation, params).perform.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips when the contact already writes the agent language' do
      conversation.update!(additional_attributes: { 'conversation_language' => 'en' })

      expect(described_class.new(user, conversation, params).perform.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips template messages' do
      message = described_class.new(user, conversation,
                                    ActionController::Parameters.new(content: 'Hello there', template_params: { name: 'order_update' })).perform

      expect(message.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips interactive content types' do
      message = described_class.new(user, conversation,
                                    ActionController::Parameters.new(content: 'Pick one', content_type: 'input_select',
                                                                     content_attributes: { items: [{ title: 'Yes', value: 'yes' }] })).perform

      expect(message.content).to eq('Pick one')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips emails sent with custom html' do
      message = described_class.new(user, conversation,
                                    ActionController::Parameters.new(content: 'Hello there', email_html_content: '<p>Hello there</p>')).perform

      expect(message.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips messages sent by a bot' do
      bot_params = ActionController::Parameters.new(content: 'Hello there', sender_type: 'AgentBot', sender_id: agent_bot.id)
      message = described_class.new(user, conversation, bot_params).perform

      expect(message.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end

    it 'skips messages without an agent' do
      expect(described_class.new(nil, conversation, params).perform.content).to eq('Hello there')
      expect(Captain::Llm::MessageTranslationService).not_to have_received(:new)
    end
  end
end
