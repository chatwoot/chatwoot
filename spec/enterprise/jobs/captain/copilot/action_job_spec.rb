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

  it 'tells the model which records already had the change, so it does not report them as failures' do
    described_class.perform_now(action_run.id)

    expect(action_run.reload.summary).to include(applied: 1, already_applied: 1, failed: 0)
  end

  it 'counts the records a stopped change never reached as not changed' do
    account.labels.find_by!(title: 'billing').destroy!

    described_class.perform_now(action_run.id)

    expect(card.reload.message.dig('approval', 'progress')).to include('finished' => true, 'applied' => 0, 'not_changed' => 2)
  end

  describe 'sending a reply' do
    let(:reply) { 'We are looking into the sign-in problem.' }
    let!(:reply_run) do
      arguments = { content: reply }
      ids = [labeled.id, unlabeled.id]
      proposed = Captain::Copilot::Actions::SendReply.new(account: account, user: user, arguments: arguments).proposal_values(ids)
      CopilotRun::Action.create!(
        account: account, user: user, copilot_thread: thread, status: :queued,
        copilot_tool_call: turn.tool_calls.create!(call_id: 'act-2', name: 'act'),
        context: { action: 'send_reply', arguments: arguments, target_ids: ids, approval_message_id: card.id, proposal_values: proposed }
      )
    end

    it 'does not reply to a conversation whose status changed after the proposal, and says why' do
      unlabeled.update!(status: :resolved)

      described_class.perform_now(reply_run.id)

      expect(labeled.messages.outgoing.pluck(:content)).to eq([reply])
      expect(unlabeled.messages.outgoing).to be_empty
      expect(reply_run.reload.summary).to include(
        applied: 1, failed: 1,
        failure_reasons: { 'The conversation was open when the reply was proposed and its status has changed since, so the reply was not sent' => 1 }
      )
    end

    it 'does not reply to a conversation that was resolved and reopened after the proposal' do
      unlabeled.update!(status: :resolved)
      unlabeled.update!(status: :open)

      described_class.perform_now(reply_run.id)

      expect(labeled.messages.outgoing.pluck(:content)).to eq([reply])
      expect(unlabeled.messages.outgoing).to be_empty
    end

    it 'keeps a saved reply applied when queueing its delivery fails, so it is never sent twice' do
      allow(SendReplyJob).to receive(:perform_later).and_raise(RuntimeError)

      described_class.perform_now(reply_run.id)

      expect(labeled.messages.outgoing.count).to eq(1)
      expect(reply_run.reload.action_items.pluck(:status)).to all(eq('applied'))
      expect(reply_run.reload).to be_completed
    end
  end

  describe 'splitting conversations across agents' do
    let(:agents) { create_list(:user, 2, account: account, role: :agent) }
    let(:other_inbox) { create(:inbox, account: account) }
    let(:targets) do
      [labeled, unlabeled, create(:conversation, account: account, inbox: inbox), create(:conversation, account: account, inbox: other_inbox)]
    end
    let(:split_run) do
      arguments = { agent_ids: agents.map(&:id) }
      ids = targets.map(&:id)
      split = Captain::Copilot::Actions::AssignAgent.new(account: account, user: user, arguments: arguments).proposal_values(ids)
      CopilotRun::Action.create!(
        account: account, user: user, copilot_thread: thread, status: :queued,
        copilot_tool_call: turn.tool_calls.create!(call_id: 'act-3', name: 'act'),
        context: { action: 'assign_agent', arguments: arguments, target_ids: ids, approval_message_id: card.id, proposal_values: split }
      )
    end

    before do
      agents.each { |agent| create(:inbox_member, user: agent, inbox: inbox) }
      create(:inbox_member, user: agents.first, inbox: other_inbox)
    end

    it 'takes turns between the agents and skips an agent who is not a member of the inbox' do
      described_class.perform_now(split_run.id)

      expect(targets.map { |conversation| conversation.reload.assignee_id }).to eq([agents.first.id, agents.second.id, agents.first.id, nil])
      expect(split_run.reload.summary).to include(applied: 3, failed: 1)
    end
  end

  describe 'applying an SLA policy' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:sla_run) do
      CopilotRun::Action.create!(
        account: account, user: user, copilot_thread: thread, status: :queued,
        copilot_tool_call: turn.tool_calls.create!(call_id: 'act-4', name: 'act'),
        context: { action: 'apply_sla', arguments: { sla_policy_id: sla_policy.id }, target_ids: [labeled.id, unlabeled.id],
                   approval_message_id: card.id }
      )
    end

    it 'fails a conversation that already has another SLA with the reason, without a retry' do
      account.enable_features!('sla')
      unlabeled.update!(sla_policy: create(:sla_policy, account: account, name: 'Premium'))
      allow(ChatwootExceptionTracker).to receive(:new).and_call_original

      described_class.perform_now(sla_run.id)

      expect(labeled.reload.sla_policy).to eq(sla_policy)
      expect(sla_run.reload).to be_incomplete
      expect(sla_run.summary).to include(applied: 1, failed: 1,
                                         failure_reasons: { 'Sla policy conversation already has a different sla' => 1 })
      expect(ChatwootExceptionTracker).not_to have_received(:new)
    end
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
      expect(action_run.reload.summary).to include(status: 'incomplete', already_applied: 1, not_processed: 1)
    end

    it 'refuses to stop a change that already finished' do
      described_class.perform_now(action_run.id)

      expect(action_run.reload.stop).to be(false)
      expect(action_run.reload).to be_completed
    end
  end
end
