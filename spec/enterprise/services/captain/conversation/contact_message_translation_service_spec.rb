require 'rails_helper'

RSpec.describe Captain::Conversation::ContactMessageTranslationService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:greeting) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Bonjour') }

  it 'queues a translation for each requested message of the conversation' do
    other_conversation = create(:conversation, account: account, inbox: inbox)
    elsewhere = create(:message, account: account, inbox: inbox, conversation: other_conversation, message_type: :incoming, content: 'Salut')

    described_class.new(conversation: conversation, message_ids: [greeting.id, elsewhere.id], target_language: 'en').perform

    expect(Captain::Conversation::MessageTranslationJob).to have_been_enqueued.with(greeting, 'en')
    expect(Captain::Conversation::MessageTranslationJob).not_to have_been_enqueued.with(elsewhere, 'en')
  end
end
