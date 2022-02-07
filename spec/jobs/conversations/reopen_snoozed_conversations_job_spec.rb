require 'rails_helper'

RSpec.describe Conversations::ReopenSnoozedConversationsJob, type: :job do
  let!(:snoozed_till_5_minutes_ago) { create(:conversation, status: :snoozed, snoozed_until: 5.minutes.ago) }
  let!(:snoozed_till_tomorrow) { create(:conversation, status: :snoozed, snoozed_until: 1.day.from_now) }
  let!(:snoozed_indefinitely) { create(:conversation, status: :snoozed) }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'reopens snoozed conversations whose snooze until has passed' do
      described_class.perform_now

      expect(snoozed_till_5_minutes_ago.reload.status).to eq 'open'
      expect(snoozed_till_tomorrow.reload.status).to eq 'snoozed'
      expect(snoozed_indefinitely.reload.status).to eq 'snoozed'
    end
  end
end
