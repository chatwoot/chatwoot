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

  describe 'delay configuration' do
    let(:account) { create(:account) }
    let(:web_widget) { create(:channel_widget, account: account) }
    let(:inbox) { create(:inbox, channel: web_widget, account: account) }

    describe '#calculate_delay' do
      it 'returns 0 when no delay config present' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: {})
        expect(campaign.calculate_delay).to eq(0)
      end

      it 'returns 0 when trigger_rules is nil' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: nil)
        expect(campaign.calculate_delay).to eq(0)
      end

      it 'returns 0 for type: "none"' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'none' } })
        expect(campaign.calculate_delay).to eq(0)
      end

      it 'returns exact value for type: "fixed"' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 5 } })
        expect(campaign.calculate_delay).to eq(5)
      end

      it 'returns value within range for type: "random"' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 3, 'max' => 10 } })
        delay = campaign.calculate_delay
        expect(delay).to be >= 3
        expect(delay).to be <= 10
      end

      it 'returns consistent value for same min and max in random delay' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 5, 'max' => 5 } })
        expect(campaign.calculate_delay).to eq(5)
      end
    end

    describe '#delay_type' do
      it 'returns "none" when no delay config present' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: {})
        expect(campaign.delay_type).to eq('none')
      end

      it 'returns "none" when trigger_rules is nil' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: nil)
        expect(campaign.delay_type).to eq('none')
      end

      it 'returns correct type from trigger_rules' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 5 } })
        expect(campaign.delay_type).to eq('fixed')
      end
    end

    describe '#delay?' do
      it 'returns false when no delay config present' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: {})
        expect(campaign.delay?).to be false
      end

      it 'returns false for type: "none"' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'none' } })
        expect(campaign.delay?).to be false
      end

      it 'returns true for type: "fixed"' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 5 } })
        expect(campaign.delay?).to be true
      end

      it 'returns true for type: "random"' do
        campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 3, 'max' => 10 } })
        expect(campaign.delay?).to be true
      end
    end

    describe 'delay validation' do
      context 'when delay type is fixed' do
        it 'accepts valid fixed delay (0 seconds)' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 0 } })
          expect(campaign).to be_valid
        end

        it 'accepts valid fixed delay (300 seconds)' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 300 } })
          expect(campaign).to be_valid
        end

        it 'rejects fixed delay less than 0' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => -1 } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Fixed delay must be between 0 and 300 seconds')
        end

        it 'rejects fixed delay greater than 300' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'fixed', 'seconds' => 301 } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Fixed delay must be between 0 and 300 seconds')
        end
      end

      context 'when delay type is random' do
        it 'accepts valid random delay' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 3, 'max' => 10 } })
          expect(campaign).to be_valid
        end

        it 'accepts random delay with min equal to max' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 5, 'max' => 5 } })
          expect(campaign).to be_valid
        end

        it 'rejects random delay with min greater than max' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 10, 'max' => 5 } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Min delay must be less than or equal to max delay')
        end

        it 'rejects random delay with min less than 0' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => -1, 'max' => 10 } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Min delay must be between 0 and 300 seconds')
        end

        it 'rejects random delay with min greater than 300' do
          campaign = build(:campaign, inbox: inbox, account: account,
                                      trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 301, 'max' => 305 } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Min delay must be between 0 and 300 seconds')
        end

        it 'rejects random delay with max less than 0' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 0, 'max' => -1 } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Max delay must be between 0 and 300 seconds')
        end

        it 'rejects random delay with max greater than 300' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'random', 'min' => 0, 'max' => 301 } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Max delay must be between 0 and 300 seconds')
        end
      end

      context 'when delay type is none' do
        it 'accepts type: none without validation' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'none' } })
          expect(campaign).to be_valid
        end
      end

      context 'when delay type is invalid' do
        it 'rejects invalid delay type' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: { 'delay' => { 'type' => 'invalid' } })
          expect(campaign).not_to be_valid
          expect(campaign.errors[:trigger_rules]).to include('Invalid delay type: invalid')
        end
      end

      context 'when no delay config is provided' do
        it 'accepts campaign without delay config (backward compatibility)' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: {})
          expect(campaign).to be_valid
        end

        it 'accepts campaign with nil trigger_rules' do
          campaign = build(:campaign, inbox: inbox, account: account, trigger_rules: nil)
          expect(campaign).to be_valid
        end
      end
    end

    describe 'message length validation' do
      it 'accepts message within the limit' do
        message = 'a' * 150_000
        campaign = build(:campaign, inbox: inbox, account: account, message: message)
        expect(campaign).to be_valid
      end

      it 'rejects message exceeding the limit' do
        message = 'a' * 150_001
        campaign = build(:campaign, inbox: inbox, account: account, message: message)
        expect(campaign).not_to be_valid
        expect(campaign.errors[:message]).to include('is too long (maximum is 150000 characters)')
      end

      it 'accepts empty message (presence validation will catch it)' do
        campaign = build(:campaign, inbox: inbox, account: account, message: '')
        expect(campaign).not_to be_valid
        expect(campaign.errors[:message]).to include("can't be blank")
      end
    end
  end
end
