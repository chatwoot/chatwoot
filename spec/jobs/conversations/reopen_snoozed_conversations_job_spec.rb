require 'rails_helper'

RSpec.describe Conversations::ReopenSnoozedConversationsJob do
  let!(:snoozed_till_5_minutes_ago) { create(:conversation, status: :snoozed, snoozed_until: 5.minutes.ago) }
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
      expect(snoozed_till_tomorrow.reload.status).to eq 'snoozed'
      expect(snoozed_indefinitely.reload.status).to eq 'snoozed'
    end
  end
end
