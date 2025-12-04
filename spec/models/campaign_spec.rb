# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Campaign do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe '.before_create' do
    let(:account) { create(:account) }
    let(:website_channel) { create(:channel_widget, account: account) }
    let(:website_inbox) { create(:inbox, channel: website_channel, account: account) }
    let(:campaign) { build(:campaign, account: account, inbox: website_inbox, display_id: nil, trigger_rules: { url: 'https://test.com' }) }

    before do
      campaign.save!
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

    let(:account) { create(:account) }
    let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
    let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
    let(:campaign) { build(:campaign, inbox: facebook_inbox, account: account) }

    it 'would not save the campaigns' do
      expect(campaign.save).to be false
      expect(campaign.errors.full_messages.first).to eq 'Inbox Unsupported Inbox type'
    end
  end

  context 'when a campaign is completed' do
    let(:account) { create(:account) }
    let(:web_widget) { create(:channel_widget, account: account) }
    let!(:campaign) { create(:campaign, account: account, inbox: web_widget.inbox, campaign_status: :completed, trigger_rules: { url: 'https://test.com' }) }

    it 'would prevent further updates' do
      campaign.title = 'new name'
      expect(campaign.save).to be false
      expect(campaign.errors.full_messages.first).to eq 'Status The campaign is already completed'
    end

    it 'can be deleted' do
      campaign.destroy!
      expect(described_class.exists?(campaign.id)).to be false
    end

    it 'cant be triggered' do
      expect(Twilio::OneoffSmsCampaignService).not_to receive(:new).with(campaign: campaign)
      expect(campaign.trigger!).to be_nil
    end
  end

  context 'when a campaign is processing' do
    let(:account) { create(:account) }
    let(:web_widget) { create(:channel_widget, account: account) }
    let!(:campaign) { create(:campaign, account: account, inbox: web_widget.inbox, campaign_status: :processing, trigger_rules: { url: 'https://test.com' }) }

    it 'cant be triggered again' do
      expect(Twilio::OneoffSmsCampaignService).not_to receive(:new).with(campaign: campaign)
      expect(campaign.trigger!).to be_nil
    end
  end

  describe 'ensure_correct_campaign_attributes' do
    context 'when Twilio SMS campaign' do
      let(:account) { create(:account) }
      let!(:twilio_sms) { create(:channel_twilio_sms, account: account) }
      let!(:twilio_inbox) { create(:inbox, channel: twilio_sms, account: account) }
      let(:campaign) { build(:campaign, account: account, inbox: twilio_inbox) }

      it 'only saves campaign type as oneoff and wont leave scheduled_at empty' do
        campaign.campaign_type = 'ongoing'
        campaign.save!
        expect(campaign.reload.campaign_type).to eq 'one_off'
        expect(campaign.scheduled_at.present?).to be true
      end

      it 'calls twilio service on trigger!' do
        sms_service = double
        expect(Twilio::OneoffSmsCampaignService).to receive(:new).with(campaign: campaign).and_return(sms_service)
        expect(sms_service).to receive(:perform)
        campaign.save!
        campaign.trigger!
      end

      it 'marks campaign as processing when triggered' do
        sms_service = double
        allow(Twilio::OneoffSmsCampaignService).to receive(:new).with(campaign: campaign).and_return(sms_service)
        allow(sms_service).to receive(:perform)
        campaign.save!
        expect { campaign.trigger! }.to change { campaign.reload.campaign_status }.from('active').to('processing')
      end
    end

    context 'when SMS campaign' do
      let(:account) { create(:account) }
      let!(:sms_channel) { create(:channel_sms, account: account) }
      let!(:sms_inbox) { create(:inbox, channel: sms_channel, account: account) }
      let(:campaign) { build(:campaign, account: account, inbox: sms_inbox) }

      it 'only saves campaign type as oneoff and wont leave scheduled_at empty' do
        campaign.campaign_type = 'ongoing'
        campaign.save!
        expect(campaign.reload.campaign_type).to eq 'one_off'
        expect(campaign.scheduled_at.present?).to be true
      end

      it 'calls sms service on trigger!' do
        sms_service = double
        expect(Sms::OneoffSmsCampaignService).to receive(:new).with(campaign: campaign).and_return(sms_service)
        expect(sms_service).to receive(:perform)
        campaign.save!
        campaign.trigger!
      end

      it 'marks campaign as processing when triggered' do
        sms_service = double
        allow(Sms::OneoffSmsCampaignService).to receive(:new).with(campaign: campaign).and_return(sms_service)
        allow(sms_service).to receive(:perform)
        campaign.save!
        expect { campaign.trigger! }.to change { campaign.reload.campaign_status }.from('active').to('processing')
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

  context 'when validating sender' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:web_widget) { create(:channel_widget, account: account) }
    let(:inbox) { create(:inbox, channel: web_widget, account: account) }

    it 'allows sender from the same account' do
      campaign = build(:campaign, inbox: inbox, account: account, sender: user)
      expect(campaign).to be_valid
    end

    it 'does not allow sender from different account' do
      other_account = create(:account)
      other_user = create(:user, account: other_account)
      campaign = build(:campaign, inbox: inbox, account: account, sender: other_user)
      expect(campaign).not_to be_valid
      expect(campaign.errors[:sender_id]).to include(
        'must belong to the same account as the campaign'
      )
    end
  end

  context 'when validating inbox' do
    let(:account) { create(:account) }
    let(:other_account) { create(:account) }
    let(:web_widget) { create(:channel_widget, account: account) }
    let(:inbox) { create(:inbox, channel: web_widget, account: account) }
    let(:other_account_inbox) { create(:inbox, account: other_account) }

    it 'allows inbox from the same account' do
      campaign = build(:campaign, inbox: inbox, account: account)
      expect(campaign).to be_valid
    end

    it 'does not allow inbox from different account' do
      campaign = build(:campaign, inbox: other_account_inbox, account: account)
      expect(campaign).not_to be_valid
      expect(campaign.errors[:inbox_id]).to include(
        'must belong to the same account as the campaign'
      )
    end
  end

  describe 'campaign_contacts preparation' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account, channel: create(:channel_twilio_sms, account: account)) }
    let(:label) { create(:label, account: account, title: 'vip') }
    let!(:contact1) { create(:contact, account: account).tap { |c| c.update(label_list: ['vip']) } }
    let!(:contact2) { create(:contact, account: account).tap { |c| c.update(label_list: ['vip']) } }

    context 'when creating a one_off campaign' do
      it 'schedules PrepareCampaignContactsJob' do
        expect(Campaigns::PrepareCampaignContactsJob).to receive(:perform_later)

        create(:campaign,
               account: account,
               inbox: inbox,
               campaign_type: :one_off,
               audience: [{ 'id' => label.id, 'type' => 'Label' }])
      end
    end

    context 'when creating an ongoing campaign' do
      let(:web_widget) { create(:channel_widget, account: account) }
      let(:website_inbox) { create(:inbox, channel: web_widget, account: account) }

      it 'does not schedule PrepareCampaignContactsJob' do
        expect(Campaigns::PrepareCampaignContactsJob).not_to receive(:perform_later)

        create(:campaign,
               account: account,
               inbox: website_inbox,
               campaign_type: :ongoing,
               trigger_rules: { url: 'https://test.com' })
      end
    end
  end

  describe 'associations for campaign_contacts' do
    it { is_expected.to have_many(:campaign_contacts).dependent(:destroy) }
    it { is_expected.to have_many(:contacts).through(:campaign_contacts) }
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:campaign_status)
        .with_values(active: 0, completed: 1, processing: 2)
        .backed_by_column_of_type(:integer)
    }

    it {
      expect(subject).to define_enum_for(:contacts_preparation_status)
        .with_values(preparing: 0, prepared: 1, failed: 2)
        .backed_by_column_of_type(:integer)
    }
  end
end
