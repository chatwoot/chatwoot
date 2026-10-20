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
      expect(described_class.episode_key_for(conversation, nil)).to eq("status:#{conversation.status_changed_at.strftime('%s%6N')}")
    end

    it 'matches between an in-memory arm and a DB-reloaded fire (no float rounding drift)' do
      conversation.status_changed_at = Time.zone.at(1_784_102_080.844761923r)
      arm_key = described_class.episode_key_for(conversation, nil)
      conversation.save!
      expect(arm_key).to eq(described_class.episode_key_for(conversation.reload, nil))
    end

    it 'derives awaiting_agent episodes from waiting_since (sub-second) for incoming messages' do
      message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      expect(described_class.episode_key_for(conversation.reload, message)).to eq("awaiting_agent:#{conversation.waiting_since.strftime('%s%6N')}")
    end

    it 'distinguishes two waiting periods that fall within the same second' do
      message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      first_key = described_class.episode_key_for(conversation.reload, message)

      # Agent replies then customer re-waits within the same second: keys must differ.
      conversation.update!(waiting_since: conversation.waiting_since + 0.4)
      expect(described_class.episode_key_for(conversation.reload, message)).not_to eq(first_key)
    end

    it 'arms an awaiting_agent episode from the message created_at when waiting_since is not yet written' do
      message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      # Simulate the race where the listener arms before update_waiting_since commits.
      conversation.update!(waiting_since: nil)
      armed_key = described_class.arm_episode_key_for(conversation.reload, message)

      # Once waiting_since settles to the message's created_at, the strict fire-time key matches.
      conversation.update!(waiting_since: message.created_at)
      expect(armed_key).to eq("awaiting_agent:#{message.created_at.strftime('%s%6N')}")
      expect(armed_key).to eq(described_class.episode_key_for(conversation.reload, message))
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

    it 'anchors due_at to the event time, not when a backlogged listener runs' do
      conversation.update!(status_changed_at: 30.minutes.ago)
      described_class.schedule(rule: rule, conversation: conversation)

      # A 60-minute rule on a status that changed 30 minutes ago is already 30 minutes into its wait.
      expect(described_class.last.due_at).to be_within(5.seconds).of(30.minutes.from_now)
    end

    it 'does not arm a status episode on a conversation that predates status_changed_at' do
      conversation.status_changed_at = nil

      expect { described_class.schedule(rule: rule, conversation: conversation) }.not_to change(described_class, :count)
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

      travel_to(30.minutes.from_now) do
        second_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
        described_class.schedule(rule: rule, conversation: conversation, message: second_reply)

        # due_at is re-anchored to the new reply's created_at, not the original schedule time.
        expect(described_class.count).to eq(1)
        expect(described_class.last.message_id).to eq(second_reply.id)
        expect(described_class.last.due_at).to be_within(5.seconds).of(60.minutes.from_now)
      end
    end

    it 'ignores a customer reply that landed while the arming job was still queued' do
      create(:message, conversation: conversation, account: account, message_type: :incoming)
      agent_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      # MESSAGE_CREATED dispatches asynchronously, so the customer can answer before the row is armed.
      late_reply = create(:message, conversation: conversation, account: account, message_type: :incoming)

      described_class.schedule(rule: rule, conversation: conversation, message: agent_reply)

      row = described_class.last
      expect(row.episode_key).not_to eq("reply_chase:#{late_reply.id}")
      # The episode is already over, so the fire-time re-check cancels the row instead of chasing.
      expect(row.episode_current?).to be(false)
    end

    it 'does not let a late older reply move the reply_chase clock backwards' do
      older_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      newer_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)

      # The newer reply's job runs first and arms the episode.
      described_class.schedule(rule: rule, conversation: conversation, message: newer_reply)
      armed_due_at = described_class.last.due_at

      # The older reply's job arrives late; it must not pull the clock or message_id back.
      described_class.schedule(rule: rule, conversation: conversation, message: older_reply)

      expect(described_class.count).to eq(1)
      expect(described_class.last.message_id).to eq(newer_reply.id)
      expect(described_class.last.due_at).to eq(armed_due_at)
    end

    it 'does not re-arm an executed reply_chase episode' do
      reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: reply)
      described_class.last.update!(status: :executed)

      described_class.schedule(rule: rule, conversation: conversation, message: reply)

      expect(described_class.count).to eq(1)
      expect(described_class.last).to be_executed
    end

    it 're-arms a condition-skipped episode when a newer qualifying message arrives' do
      first_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: first_reply)
      described_class.last.update!(status: :skipped, skip_reason: 'conditions_changed')

      second_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: second_reply)

      row = described_class.last
      expect(described_class.count).to eq(1)
      expect(row).to be_pending
      expect(row.skip_reason).to be_nil
      expect(row.message_id).to eq(second_reply.id)
    end

    it 're-anchors a reply_chase row stuck in processing when a newer reply arrives' do
      first_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: first_reply)
      # The worker claimed the row and then died, leaving it in processing with the old clock.
      described_class.last.update!(status: :processing)

      travel_to(30.minutes.from_now) do
        second_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
        described_class.schedule(rule: rule, conversation: conversation, message: second_reply)

        row = described_class.last
        expect(described_class.count).to eq(1)
        expect(row).to be_pending
        expect(row.message_id).to eq(second_reply.id)
        expect(row.due_at).to be_within(5.seconds).of(60.minutes.from_now)
      end
    end

    it 're-arms an episode skipped for a reason other than conditions, so later messages are not suppressed' do
      reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: reply)
      # The sweep was down long enough for the row to age out; a disabled rule leaves the same trail.
      described_class.last.update!(status: :skipped, skip_reason: 'expired')

      newer_reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      described_class.schedule(rule: rule, conversation: conversation, message: newer_reply)

      row = described_class.last
      expect(described_class.count).to eq(1)
      expect(row).to be_pending
      expect(row.skip_reason).to be_nil
      expect(row.message_id).to eq(newer_reply.id)
    end

    it 'keeps the awaiting_agent clock but tracks the newest incoming message' do
      first_message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      described_class.schedule(rule: rule, conversation: conversation, message: first_message)
      original_due_at = described_class.last.due_at

      second_message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      travel_to(30.minutes.from_now) { described_class.schedule(rule: rule, conversation: conversation, message: second_message) }

      row = described_class.last
      expect(described_class.count).to eq(1)
      # The wait still counts from waiting_since, so the clock is unchanged...
      expect(row.due_at).to be_within(1.second).of(original_due_at)
      # ...but the row tracks the newest qualifying message, not the stale first one.
      expect(row.message_id).to eq(second_message.id)
    end

    it 'keeps the newest message when an older incoming collision arrives last' do
      first_message = create(:message, conversation: conversation, account: account, message_type: :incoming)
      described_class.schedule(rule: rule, conversation: conversation, message: first_message)

      older = create(:message, conversation: conversation, account: account, message_type: :incoming)
      newer = create(:message, conversation: conversation, account: account, message_type: :incoming)

      # The newer message re-arms first; a late older-message collision must not overwrite it.
      described_class.schedule(rule: rule, conversation: conversation, message: newer)
      described_class.schedule(rule: rule, conversation: conversation, message: older)

      expect(described_class.count).to eq(1)
      expect(described_class.last.message_id).to eq(newer.id)
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

    it 'is true for a factory-built row anchored on a message' do
      reply = create(:message, conversation: conversation, account: account, message_type: :outgoing)
      row = create(:automation_rule_pending_execution, account: account, conversation: conversation, message: reply)

      expect(row.episode_current?).to be(true)
    end
  end

  describe '#claim!' do
    let(:row) { create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 1.minute.ago) }

    it 'claims a pending row exactly once so a duplicate enqueue cannot double-fire' do
      expect(row.claim!).to be(true)
      expect(row.reload).to be_processing
      expect(described_class.find(row.id).claim!).to be(false)
    end

    it 'does not claim a row whose due_at was pushed into the future (reply-chase reschedule)' do
      row.update!(due_at: 1.hour.from_now)
      expect(row.claim!).to be(false)
    end

    it 'does not claim terminal rows' do
      row.update!(status: :executed)
      expect(row.claim!).to be(false)
    end

    it 'reclaims a processing row only after its lock goes stale' do
      row.update!(status: :processing)
      expect(row.claim!).to be(false)

      travel_to(20.minutes.from_now) { expect(row.claim!).to be(true) }
    end
  end

  describe '.sweepable' do
    it 'selects due pending rows and stale processing rows, but not future or fresh ones' do
      due = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 1.minute.ago)
      create(:automation_rule_pending_execution, account: account, due_at: 1.hour.from_now)
      create(:automation_rule_pending_execution, account: account, status: :processing)
      stale = travel_to(20.minutes.ago) do
        create(:automation_rule_pending_execution, account: account, conversation: conversation, status: :processing)
      end

      expect(described_class.sweepable).to contain_exactly(due, stale)
    end
  end

  describe '.purge_terminal!' do
    it 'deletes terminal rows past the retention window and keeps everything else' do
      old_executed = travel_to(31.days.ago) { create(:automation_rule_pending_execution, account: account, status: :executed) }
      recent_skipped = create(:automation_rule_pending_execution, account: account, status: :skipped)
      pending = create(:automation_rule_pending_execution, account: account, conversation: conversation)

      described_class.purge_terminal!

      expect(described_class.pluck(:id)).to contain_exactly(recent_skipped.id, pending.id)
      expect { old_executed.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.reschedule_paused' do
    it 'resets rows overdue past the window so a resumed account replays them instead of expiring' do
      expired = create(:automation_rule_pending_execution, account: account, conversation: conversation, due_at: 5.days.ago)
      within_window = create(:automation_rule_pending_execution, account: account, due_at: 2.days.ago)

      described_class.reschedule_paused(account)

      expect(expired.reload.due_at).to be_within(5.seconds).of(Time.current)
      expect(within_window.reload.due_at).to be_within(5.seconds).of(2.days.ago)
    end

    it 'hands a stale processing row back to pending instead of leaving it to expire on the next sweep' do
      stale = travel_to(5.days.ago) do
        create(:automation_rule_pending_execution, account: account, conversation: conversation, status: :processing)
      end

      described_class.reschedule_paused(account)

      expect(stale.reload).to be_pending
      expect(stale.due_at).to be_within(5.seconds).of(Time.current)
    end

    it 'leaves a live worker holding its own row' do
      claimed = create(:automation_rule_pending_execution, account: account, conversation: conversation,
                                                           status: :processing, due_at: 5.days.ago)

      described_class.reschedule_paused(account)

      expect(claimed.reload).to be_processing
      expect(claimed.due_at).to be_within(5.seconds).of(5.days.ago)
    end
  end
end
