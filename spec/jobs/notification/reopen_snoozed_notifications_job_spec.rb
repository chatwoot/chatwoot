require 'rails_helper'

RSpec.describe Notification::ReopenSnoozedNotificationsJob do
  let!(:snoozed_till_5_minutes_ago) { create(:notification, snoozed_until: 5.minutes.ago) }
  let!(:snoozed_till_tomorrow) { create(:notification, snoozed_until: 1.day.from_now) }
  let!(:snoozed_indefinitely) { create(:notification) }

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'reopens snoozed notifications whose snooze until has passed' do
      described_class.perform_now

      snoozed_until = snoozed_till_5_minutes_ago.reload.snoozed_until

      expect(snoozed_till_5_minutes_ago.reload.snoozed_until).to be_nil
      expect(snoozed_till_tomorrow.reload.snoozed_until.to_date).to eq 1.day.from_now.to_date
      expect(snoozed_indefinitely.reload.snoozed_until).to be_nil
      expect(snoozed_indefinitely.reload.read_at).to be_nil
      expect(snoozed_until).to eq(snoozed_till_5_minutes_ago.reload.meta['snoozed_until'])
    end
  end
end
