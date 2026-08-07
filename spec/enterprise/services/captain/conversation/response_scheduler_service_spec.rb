require 'rails_helper'

RSpec.describe Captain::Conversation::ResponseSchedulerService do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :pending) }
  let!(:message) { create(:message, conversation: conversation, message_type: :incoming, account: account) }

  before do
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
    message.inbox.reload
    allow(Captain::Conversation::ResponseLifecycleLogger).to receive(:info)
  end

  it 'logs an enqueue failure and raises it' do
    error = RedisClient::CannotConnectError.new('redis unavailable')
    allow(Captain::Conversation::ResponseBuilderJob).to receive(:perform_later).and_raise(error)
    allow(Captain::Conversation::ResponseLifecycleLogger).to receive(:error)

    expect { described_class.new(message: message).perform }.to raise_error(error)
    expect(Captain::Conversation::ResponseLifecycleLogger).to have_received(:error).with(
      :enqueue_failed,
      account_id: account.id,
      conversation_id: conversation.id,
      conversation_display_id: conversation.display_id,
      inbox_id: inbox.id,
      assistant_id: assistant.id,
      message_id: message.id,
      conversation_status: 'pending',
      wait_seconds: 0.0,
      error_class: 'RedisClient::CannotConnectError'
    )
  end
end
