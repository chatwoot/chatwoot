require 'rails_helper'

describe Sms::OneoffSmsCampaignService do
  subject(:sms_campaign_service) { described_class.new(campaign: campaign) }

  let(:account) { create(:account) }
  let!(:sms_channel) { create(:channel_sms) }
  let!(:sms_inbox) { create(:inbox, channel: sms_channel) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }
  let!(:campaign) do
    create(:campaign, inbox: sms_inbox, account: account,
                      audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }])
  end

  describe 'perform' do
    before do
      stub_request(:post, 'https://messaging.bandwidth.com/api/v2/users/1/messages').to_return(
        status: 200,
        body: { 'id' => '1' }.to_json,
        headers: {}
      )
    end

    it 'raises error if the campaign is completed' do
      campaign.completed!

      expect { sms_campaign_service.perform }.to raise_error 'Completed Campaign'
    end

    it 'raises error invalid campaign when its not a oneoff sms campaign' do
      campaign = create(:campaign)

      expect { described_class.new(campaign: campaign).perform }.to raise_error "Invalid campaign #{campaign.id}"
    end

    it 'send messages to contacts in the audience and marks the campaign completed' do
      contact_with_label1, contact_with_label2, contact_with_both_labels = FactoryBot.create_list(:contact, 3, :with_phone_number, account: account)
      contact_with_label1.update_labels([label1.title])
      contact_with_label2.update_labels([label2.title])
      contact_with_both_labels.update_labels([label1.title, label2.title])
      sms_campaign_service.perform
      assert_requested(:post, 'https://messaging.bandwidth.com/api/v2/users/1/messages', times: 3)
      expect(campaign.reload.completed?).to eq true
    end
  end
end
