require 'rails_helper'

RSpec.describe Migration::BackfillConversationLastMessageAtJob do
  let(:account) { create(:account) }
  let(:history) { create(:conversation, account: account) }
  let(:time) { Time.current.change(usec: 123_456) }

  it 'reconciles populated rows, skips private and activity messages, and preserves operational timestamps' do
    create(:message, conversation: history, account: account, created_at: time)
    create(:message, conversation: history, account: account, created_at: time + 1.hour, private: true)
    create(:message, conversation: history, account: account, created_at: time + 2.hours, message_type: :activity)
    history.update!(last_message_at: time - 1.day)
    original = history.reload.attributes.slice('last_activity_at', 'updated_at')
    empty = create(:conversation, account: account)
    create(:message, conversation: empty, account: account, private: true)

    2.times { described_class.perform_now(account) }

    expect(history.reload.last_message_at).to eq(time)
    expect(history.attributes.slice('last_activity_at', 'updated_at')).to eq(original)
    expect(empty.reload.last_message_at).to be_nil
  end

  it 'resumes after the last processed id and protects a newer writer' do
    stub_const("#{described_class}::BATCH_SIZE", 1)
    create(:message, conversation: history, account: account, created_at: time)
    history.update!(last_message_at: time + 1.day)
    next_conversation = create(:conversation, account: account)
    create(:message, conversation: next_conversation, account: account, created_at: time)
    next_conversation.update!(last_message_at: nil)

    expect { described_class.perform_now(account) }.to have_enqueued_job(described_class).with(account, history.id, next_conversation.id)
    expect(next_conversation.reload.last_message_at).to be_nil
    described_class.perform_now(account, history.id, next_conversation.id)

    expect(next_conversation.reload.last_message_at).to eq(time)
    expect(history.reload.last_message_at).to eq(time + 1.day)
  end
end
