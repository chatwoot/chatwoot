require 'rails_helper'

RSpec.describe Captain::ConversationOutcomeBoundaryJob do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
  end

  it 'inserts the reopen boundary for the conversation stream' do
    create(
      :conversation_outcome,
      account: account, assistant: assistant, conversation: conversation, inbox: inbox,
      started_at: 1.hour.ago
    )
    boundary_at = 5.minutes.ago.change(usec: 0)

    described_class.perform_now(conversation, boundary_at)

    expect(ConversationOutcome.where(conversation_id: conversation.id).order(:started_at).last).to have_attributes(
      episode_trigger: 'reopen',
      started_at: boundary_at
    )
  end

  it 'raises so the job retries instead of failing open' do
    create(
      :conversation_outcome,
      account: account, assistant: assistant, conversation: conversation, inbox: inbox,
      started_at: 1.hour.ago
    )
    allow(ConversationOutcome).to receive(:create!).and_raise(ActiveRecord::StatementInvalid)

    expect do
      described_class.perform_now(conversation, Time.current)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
