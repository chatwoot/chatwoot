require 'rails_helper'

RSpec.describe Captain::Copilot::ActionJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:labeled) { create(:conversation, account: account, inbox: inbox) }
  let(:unlabeled) { create(:conversation, account: account, inbox: inbox) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message) }
  let(:card) do
    thread.copilot_messages.create!(message_type: :assistant_approval, message: { approval: { status: 'approved', count: 2 } })
  end
  let(:action_run) do
    CopilotRun::Action.create!(
      account: account, user: user, copilot_thread: thread, status: :queued,
      copilot_tool_call: turn.tool_calls.create!(call_id: 'act-1', name: 'act'),
      context: { action: 'add_labels', arguments: { labels: ['billing'] }, target_ids: [labeled.id, unlabeled.id],
                 approval_message_id: card.id }
    )
  end

  before do
    account.enable_features!('copilot_workflows')
    create(:label, account: account, title: 'billing')
    labeled.add_labels(['billing'])
  end

  it 'writes the result on the approval card, counting records that already had the change as applied' do
    described_class.perform_now(action_run.id)

    expect(unlabeled.reload.label_list).to eq(['billing'])
    expect(card.reload.message['approval']).to include(
      'status' => 'approved',
      'progress' => { 'finished' => true, 'done' => 2, 'total' => 2, 'applied' => 2, 'not_changed' => 0 }
    )
  end

  it 'counts the records a stopped change never reached as not changed' do
    account.labels.find_by!(title: 'billing').destroy!

    described_class.perform_now(action_run.id)

    expect(card.reload.message.dig('approval', 'progress')).to include('finished' => true, 'applied' => 0, 'not_changed' => 2)
  end
end
