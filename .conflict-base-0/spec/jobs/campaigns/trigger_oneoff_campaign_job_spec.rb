require 'rails_helper'

RSpec.describe Campaigns::TriggerOneoffCampaignJob do
  let(:account) { create(:account) }
  let!(:twilio_sms) { create(:channel_twilio_sms, account: account) }
  let!(:twilio_inbox) { create(:inbox, channel: twilio_sms, account: account) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }

  let!(:campaign) do
    create(:campaign, inbox: twilio_inbox, account: account, audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }])
  end

  it 'enqueues the job' do
    expect { described_class.perform_later(campaign) }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called with a campaign' do
    it 'triggers the campaign' do
      expect(campaign).to receive(:trigger!)
      described_class.perform_now(campaign)
    end
  end
end
