# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Campaign, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe '.before_create' do
    let(:campaign) { build(:campaign, display_id: nil) }

    before do
      campaign.save
      campaign.reload
    end

    it 'runs before_create callbacks' do
      expect(campaign.display_id).to eq(1)
    end
  end

  context 'when Inbox other then Website or Twilio SMS' do
    before do
      stub_request(:post, /graph.facebook.com/)
    end

    let!(:facebook_channel) { create(:channel_facebook_page) }
    let!(:facebook_inbox) { create(:inbox, channel: facebook_channel) }
    let(:campaign) { build(:campaign, inbox: facebook_inbox) }

    it 'would not save the campaigns' do
      expect(campaign.save).to eq false
      expect(campaign.errors.full_messages.first).to eq 'Inbox Unsupported Inbox type'
    end
  end

  context 'when a campaign is completed' do
    let!(:campaign) { create(:campaign, campaign_status: :completed) }

    it 'would prevent further updates' do
      campaign.title = 'new name'
      expect(campaign.save).to eq false
      expect(campaign.errors.full_messages.first).to eq 'Status The campaign is already completed'
    end

    it 'can be deleted' do
      campaign.destroy!
      expect(described_class.exists?(campaign.id)).to eq false
    end

    it 'cant be triggered' do
      expect(Twilio::OneoffSmsCampaignService).not_to receive(:new).with(campaign: campaign)
      expect(campaign.trigger!).to eq nil
    end
  end

  describe 'ensure_correct_campaign_attributes' do
    context 'when Twilio SMS campaign' do
      let!(:twilio_sms) { create(:channel_twilio_sms) }
      let!(:twilio_inbox) { create(:inbox, channel: twilio_sms) }
      let(:campaign) { build(:campaign, inbox: twilio_inbox) }

      it 'only saves campaign type as oneoff and wont leave scheduled_at empty' do
        campaign.campaign_type = 'ongoing'
        campaign.save!
        expect(campaign.reload.campaign_type).to eq 'one_off'
        expect(campaign.scheduled_at.present?).to eq true
      end

      it 'calls twilio service on trigger!' do
        sms_service = double
        expect(Twilio::OneoffSmsCampaignService).to receive(:new).with(campaign: campaign).and_return(sms_service)
        expect(sms_service).to receive(:perform)
        campaign.save!
        campaign.trigger!
      end
    end

    context 'when Website campaign' do
      let(:campaign) { build(:campaign) }

      it 'only saves campaign type as ongoing' do
        campaign.campaign_type = 'one_off'
        campaign.save!
        expect(campaign.reload.campaign_type).to eq 'ongoing'
      end
    end
  end
end
