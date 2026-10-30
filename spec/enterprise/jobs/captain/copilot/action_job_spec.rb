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
      'progress' => { 'finished' => true, 'stopped' => false, 'done' => 2, 'total' => 2, 'applied' => 2, 'not_changed' => 0 }
    )
  end

  it 'counts the records a stopped change never reached as not changed' do
    account.labels.find_by!(title: 'billing').destroy!

    described_class.perform_now(action_run.id)

    expect(card.reload.message.dig('approval', 'progress')).to include('finished' => true, 'applied' => 0, 'not_changed' => 2)
  end

  describe 'stopping the change' do
    it 'changes nothing when the agent stops it before the job runs' do
      expect(action_run.stop).to be(true)

      described_class.perform_now(action_run.id)

      expect(unlabeled.reload.label_list).to be_empty
      expect(action_run.reload).to be_incomplete
      expect(action_run.copilot_tool_call.reload.result).to include('error' => I18n.t('captain.copilot.stopped'))
      expect(card.reload.message.dig('approval', 'progress')).to include('finished' => true, 'stopped' => true, 'not_changed' => 2)
    end

    it 'keeps the records already changed and changes none after the stop' do
      action = action_run.action
      allow(Captain::Copilot::Actions).to receive(:build).and_return(action)
      allow(action).to receive(:perform).and_wrap_original do |original, record|
        CopilotRun::Action.find(action_run.id).stop if record.id == labeled.id
        original.call(record)
      end

      described_class.perform_now(action_run.id)

      expect(action_run.action_items.pluck(:record_id)).to eq([labeled.id])
      expect(unlabeled.reload.label_list).to be_empty
      expect(action_run.reload.summary).to include(status: 'incomplete', skipped: 1, not_processed: 1)
    end

    it 'refuses to stop a change that already finished' do
      described_class.perform_now(action_run.id)

      expect(action_run.reload.stop).to be(false)
      expect(action_run.reload).to be_completed
    end
  end
end
