require 'rails_helper'

RSpec.describe Conversations::ReopenSnoozedConversationsJob do
  let!(:snoozed_till_5_minutes_ago) { create(:conversation, status: :snoozed, snoozed_until: 5.minutes.ago) }
  let!(:snoozed_till_4_days_ago) { create(:conversation, status: :snoozed, snoozed_until: 4.days.ago) }
  let!(:snoozed_till_tomorrow) { create(:conversation, status: :snoozed, snoozed_until: 1.day.from_now) }
  let!(:snoozed_indefinitely) { create(:conversation, status: :snoozed) }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'reopens snoozed conversations whose snooze until has passed' do
      agent_bot = create(:agent_bot, account: snoozed_till_5_minutes_ago.account)
      snoozed_till_5_minutes_ago.update!(ai_assignee: agent_bot)

      described_class.perform_now

      expect(snoozed_till_5_minutes_ago.reload).to have_attributes(status: 'open', ai_assignee_type: nil, assignee_agent_bot_id: nil)
      expect(snoozed_till_4_days_ago.reload.status).to eq 'open'
      expect(snoozed_till_tomorrow.reload.status).to eq 'snoozed'
      expect(snoozed_indefinitely.reload.status).to eq 'snoozed'
    end

    it 'reopens up to the batch limit and re-enqueues for remaining conversations' do
      expect do
        described_class.perform_now(1)
      end.to have_enqueued_job(described_class).with(1).on_queue('low')

      expect(snoozed_till_4_days_ago.reload.status).to eq 'open'
      expect(snoozed_till_5_minutes_ago.reload.status).to eq 'snoozed'
    end

    it 'does not reopen conversations while another worker holds the Redis lock' do
      manager = Redis::LockManager.new
      expect(manager.lock(Redis::Alfred::REOPEN_SNOOZED_CONVERSATIONS_MUTEX, described_class::LOCK_TIMEOUT)).to be(true)

      described_class.perform_now

      expect(snoozed_till_4_days_ago.reload.status).to eq 'snoozed'
      expect(snoozed_till_5_minutes_ago.reload.status).to eq 'snoozed'
    ensure
      manager.unlock(Redis::Alfred::REOPEN_SNOOZED_CONVERSATIONS_MUTEX)
    end

    it 'skips conversations that have already been reopened concurrently' do
      allow_any_instance_of(Conversation).to receive(:snoozed?).and_return(false) # rubocop:disable RSpec/AnyInstance

      expect do
        described_class.perform_now
      end.not_to have_enqueued_job(described_class)

      expect(snoozed_till_4_days_ago.reload.status).to eq 'snoozed'
    end

    it 'skips conversations that were re-snoozed to a future time concurrently' do
      allow_any_instance_of(Conversation).to receive(:snoozed_until).and_return(2.hours.from_now) # rubocop:disable RSpec/AnyInstance

      expect do
        described_class.perform_now
      end.not_to have_enqueued_job(described_class)

      expect(snoozed_till_4_days_ago.reload.status).to eq 'snoozed'
    end

    it 'releases the Redis lock before re-enqueuing continuation' do
      lock_manager = instance_double(Redis::LockManager)
      allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
      allow(lock_manager).to receive(:lock).and_return(true)

      unlocked = false
      allow(lock_manager).to receive(:unlock) do
        unlocked = true
        true
      end

      allow(described_class).to receive(:perform_later) do
        expect(unlocked).to be(true)
      end

      described_class.perform_now(1)
    end

    it 're-enqueues continuation when a full batch has a concurrently skipped conversation' do
      allow(snoozed_till_4_days_ago).to receive(:snoozed?).and_return(false)

      expect do
        described_class.perform_now(1)
      end.to have_enqueued_job(described_class).with(1).on_queue('low')
    end

    it 'stops processing and re-enqueues when execution time exceeds MAX_EXECUTION_TIME' do
      start_time = Time.zone.now
      allow(Time).to receive(:current).and_return(start_time, start_time + 9.minutes)

      expect do
        described_class.perform_now(500)
      end.to have_enqueued_job(described_class).with(500).on_queue('low')
    end
  end
end
