require 'rails_helper'

RSpec.describe AutomationRulePendingExecution do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:rule) do
    create(:automation_rule, account: account, event_name: 'conversation_updated', execution_delay: 60,
                             actions: [{ 'action_name' => 'add_label', 'action_params' => ['stale'] }])
  end

  describe '.episode_key_for' do
    it 'derives status episodes from status_changed_at' do
      expect(described_class.episode_key_for(conversation, nil)).to eq("status:#{conversation.status_changed_at.to_f}")
    end

    it 'falls back to created_at when status_changed_at is blank' do
      conversation.update!(status_changed_at: nil)
      expect(described_class.episode_key_for(conversation.reload, nil)).to eq("status:#{conversation.created_at.to_f}")
    end

    it 'derives awaiting_agent episodes from waiting_since for incoming messages' do
      message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      expect(described_class.episode_key_for(conversation.reload, message)).to eq("awaiting_agent:#{conversation.waiting_since.to_i}")
    end

    it 'derives reply_chase episodes from the max incoming message id for outgoing messages' do
      incoming = create(:message, conversation: conversation, account: account, message_type: :incoming)
      outgoing = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      expect(described_class.episode_key_for(conversation.reload, outgoing)).to eq("reply_chase:#{incoming.id}")
    end

    it 'uses 0 for reply_chase when there is no incoming message' do
      outgoing = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      expect(described_class.episode_key_for(conversation.reload, outgoing)).to eq('reply_chase:0')
    end
  end

  describe '.schedule' do
    it 'creates a pending row due after the rule delay' do
      described_class.schedule(rule: rule, conversation: conversation)

      row = described_class.last
      expect(row).to have_attributes(account_id: account.id, conversation_id: conversation.id, status: 'pending')
      expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
    end

    it 'does not reset the clock for a repeated status episode' do
      described_class.schedule(rule: rule, conversation: conversation)
      original_due_at = described_class.last.due_at

      travel_to(30.minutes.from_now) { described_class.schedule(rule: rule, conversation: conversation) }

      expect(described_class.count).to eq(1)
      expect(described_class.last.due_at).to be_within(1.second).of(original_due_at)
    end

    it 'moves the clock and anchor for a repeated reply_chase episode' do
      first_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: first_reply)

      second_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      travel_to(30.minutes.from_now) do
        described_class.schedule(rule: rule, conversation: conversation, message: second_reply)

        expect(described_class.count).to eq(1)
        expect(described_class.last.message_id).to eq(second_reply.id)
        expect(described_class.last.due_at).to be_within(5.seconds).of(60.minutes.from_now)
      end
    end

    it 'does not re-arm an executed reply_chase episode' do
      reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: reply)
      described_class.last.update!(status: :executed)

      described_class.schedule(rule: rule, conversation: conversation, message: reply)

      expect(described_class.count).to eq(1)
      expect(described_class.last).to be_executed
    end

    it 'does not reset the clock for a repeated awaiting_agent episode' do
      first_message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      described_class.schedule(rule: rule, conversation: conversation, message: first_message)
      original_due_at = described_class.last.due_at

      second_message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      travel_to(30.minutes.from_now) { described_class.schedule(rule: rule, conversation: conversation, message: second_message) }

      expect(described_class.count).to eq(1)
      expect(described_class.last.due_at).to be_within(1.second).of(original_due_at)
    end
  end

  describe '#episode_current?' do
    it 'is true while the conversation stays in the armed status' do
      described_class.schedule(rule: rule, conversation: conversation)
      expect(described_class.last.episode_current?).to be(true)
    end

    it 'is false after a status transition' do
      described_class.schedule(rule: rule, conversation: conversation)
      conversation.update!(status: :resolved)
      expect(described_class.last.reload.episode_current?).to be(false)
    end

    it 'is false for awaiting_agent episodes once the agent replies (waiting_since cleared)' do
      message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      described_class.schedule(rule: rule, conversation: conversation, message: message)

      conversation.update!(waiting_since: nil)
      expect(described_class.last.episode_current?).to be(false)
    end

    it 'is false for reply_chase episodes once the customer replies' do
      reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: reply)

      create(:message, conversation: conversation, account: account, message_type: :incoming)
      expect(described_class.last.episode_current?).to be(false)
    end
  end

  describe '#mark_processing!' do
    let(:row) { create(:automation_rule_pending_execution, account: account, conversation: conversation) }

    it 'claims a pending row exactly once' do
      expect(row.mark_processing!).to be(true)
      expect(row.reload).to be_processing
      expect(row.mark_processing!).to be(false)
    end

    it 'does not claim executed rows' do
      row.update!(status: :executed)
      expect(row.mark_processing!).to be(false)
    end
  end

  describe '.due / .expire_overdue! / .reclaim_stale!' do
    it 'selects only pending rows inside the due window' do
      due = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 1.minute.ago)
      create(:automation_rule_pending_execution, account: account, due_at: 1.hour.from_now)
      create(:automation_rule_pending_execution, account: account, due_at: 1.minute.ago, status: :executed)

      expect(described_class.due).to eq([due])
    end

    it 'expires pending rows older than the due window' do
      overdue = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 4.days.ago)
      fresh = create(:automation_rule_pending_execution, account: account, due_at: 1.minute.ago)

      expect(described_class.expire_overdue!).to eq(1)
      expect(overdue.reload).to be_skipped
      expect(overdue.skip_reason).to eq('expired')
      expect(fresh.reload).to be_pending
    end

    it 'reclaims processing rows stuck longer than the stale timeout' do
      stale = travel_to(20.minutes.ago) do
        create(:automation_rule_pending_execution, account: account, conversation: conversation, status: :processing)
      end
      recent = create(:automation_rule_pending_execution, account: account, status: :processing)

      expect(described_class.reclaim_stale!).to eq(1)
      expect(stale.reload).to be_pending
      expect(recent.reload).to be_processing
    end
  end
end
