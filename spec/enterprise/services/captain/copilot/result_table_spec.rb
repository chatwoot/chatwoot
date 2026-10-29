require 'rails_helper'

RSpec.describe Captain::Copilot::ResultTable do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:member_inbox) { create(:inbox, account: account) }
  let(:visible) { create(:conversation, account: account, inbox: member_inbox) }
  let(:hidden) { create(:conversation, account: account, inbox: create(:inbox, account: account)) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: agent) }
  let(:turn) do
    CopilotRun::Turn.create!(account: account, user: agent, copilot_thread: thread,
                             copilot_message: create(:captain_copilot_message, account: account, copilot_thread: thread))
  end
  let(:collection) do
    CopilotRun::Collection.create!(account: account, user: agent, copilot_thread: thread, status: :completed,
                                   context: { resource: 'conversations', selected_ids: [visible.id, hidden.id], as_of: Time.current.iso8601 })
  end
  let(:review) do
    CopilotRun::Review.create!(account: account, user: agent, copilot_thread: thread, source_run: collection, status: :completed,
                               copilot_tool_call: turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations'),
                               context: { criteria: 'Is this about billing?', turn_start: 0, turn_limit: 2 })
  end

  before do
    create(:inbox_member, user: agent, inbox: member_inbox)
    review.findings.create!(conversation_id: visible.id, status: :reviewed, matched: true, category: 'invoice', reason: 'Asks about an invoice')
    review.findings.create!(conversation_id: hidden.id, status: :reviewed, matched: true, category: 'refund', reason: 'Asks for a refund')
  end

  it 'shows the findings and categories only of the conversations the user can still see' do
    content = described_class.new(review).page(1)[:content]

    expect(content).to include('invoice (1)', 'Asks about an invoice')
    expect(content).not_to include('refund')
  end
end
