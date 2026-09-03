require 'rails_helper'

RSpec.describe Captain::Conversation::ResolutionMessageService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account, config: assistant_config) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant_config) { { 'resolution_message' => 'Thanks for contacting us.' } }

  before { account.enable_features('captain_integration_v2') }

  it 'creates the configured public resolution message' do
    message = described_class.new(conversation: conversation, assistant: assistant).perform

    expect(message).to have_attributes(
      content: 'Thanks for contacting us.',
      message_type: 'outgoing',
      private: false,
      sender: assistant
    )
  end

  it 'uses the default resolution message when no custom message is configured' do
    assistant.update!(config: assistant.config.except('resolution_message'))

    message = described_class.new(conversation: conversation, assistant: assistant).perform(use_default_message: true)

    expect(message.content).to eq(I18n.t('conversations.activity.auto_resolution_message'))
  end

  it 'does not use the inactivity message outside an inactivity resolution' do
    assistant.update!(config: assistant.config.except('resolution_message'))

    expect do
      described_class.new(conversation: conversation, assistant: assistant).perform
    end.not_to change(conversation.messages, :count)
  end

  it 'does not create a message when resolution messages are disabled' do
    assistant.update!(send_inactivity_resolution_message: false)

    expect do
      described_class.new(conversation: conversation, assistant: assistant).perform
    end.not_to change(conversation.messages, :count)
  end
end
