require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::ActService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversations) { create_list(:conversation, 3, account: account, inbox: inbox) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: admin) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: admin, copilot_thread: thread, copilot_message: message) }
  let(:collection) do
    CopilotRun::Collection.create!(account: account, user: admin, copilot_thread: thread, status: :completed,
                                   context: { resource: 'conversations', selected_ids: conversations.map(&:id), filters: {},
                                              as_of: Time.current.iso8601 })
  end
  let(:tool) do
    described_class.new(thread.assistant, user: admin, run: turn, lease_token: turn.claim)
                   .tap { |act_tool| act_tool.tool_call = turn.tool_calls.create!(call_id: 'act-1', name: 'act') }
  end
  let(:card) { thread.copilot_messages.find_by!(message_type: :assistant_approval).message['approval'] }

  it "shows each agent's share of the conversations on the card" do
    agents = create_list(:user, 2, account: account, role: :agent)

    tool.execute(saved_set_id: collection.id, action: 'assign_agent', arguments: { agent_ids: agents.map(&:id) })

    expect(card).to include('summary' => 'ASSIGN_AGENT', 'values' => { 'agents' => "#{agents.first.name} (2), #{agents.second.name} (1)" })
  end

  it 'warns on the card when the review did not read every conversation it selected' do
    create(:label, account: account, title: 'sign-in')
    review = CopilotRun::Review.create!(
      account: account, user: admin, copilot_thread: thread, source_run: collection, status: :completed,
      copilot_tool_call: turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations'),
      context: { criteria: 'Could the customer not sign in?', turn_start: 0, turn_start_matched: 0, turn_start_failed: 0, turn_limit: 3 }
    )
    review.findings.create!(conversation_id: conversations.first.id, status: :reviewed, matched: true)
    review.findings.create!(conversation_id: conversations.second.id, status: :failed)

    tool.execute(saved_set_id: review.id, action: 'add_labels', arguments: { labels: ['sign-in'] })

    expect(card).to include('count' => 1, 'coverage' => { 'reviewed' => 1, 'total' => 3 })
  end

  it 'gives the card the label titles to show as chips and the time the approval expires' do
    create(:label, account: account, title: 'sign-in')

    freeze_time do
      tool.execute(saved_set_id: collection.id, action: 'add_labels', arguments: { labels: ['sign-in'] })

      expect(card).to include('values' => { 'labels' => ['sign-in'] }, 'expires_at' => 5.minutes.from_now.to_i)
      expect(card['targets'].size).to eq(3)
    end
  end
end
