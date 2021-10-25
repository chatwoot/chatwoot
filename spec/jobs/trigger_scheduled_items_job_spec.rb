require 'rails_helper'

RSpec.describe TriggerScheduledItemsJob, type: :job do
  subject(:job) { described_class.perform_later }

  let(:account) { create(:account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  context 'when unexecuted Scheduled campaign jobs' do
    let!(:twilio_sms) { create(:channel_twilio_sms) }
    let!(:twilio_inbox) { create(:inbox, channel: twilio_sms) }

    it 'triggers Campaigns::TriggerOneoffCampaignJob' do
      campaign = create(:campaign, inbox: twilio_inbox)
      create(:campaign, inbox: twilio_inbox, scheduled_at: 10.days.after)
      expect(Campaigns::TriggerOneoffCampaignJob).to receive(:perform_later).with(campaign).once
      described_class.perform_now
    end

    it 'triggers Conversations::ReopenSnoozedConversationsJob' do
      expect(Conversations::ReopenSnoozedConversationsJob).to receive(:perform_later).once
      described_class.perform_now
    end
  end
end
