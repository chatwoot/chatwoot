require 'rails_helper'

describe Twilio::OneoffSmsCampaignService do
  subject(:sms_campaign_service) { described_class.new(campaign: campaign) }

  let(:account) { create(:account) }
  let!(:twilio_sms) { create(:channel_twilio_sms) }
  let!(:twilio_inbox) { create(:inbox, channel: twilio_sms) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }
  let!(:campaign) do
    create(:campaign, inbox: twilio_inbox, account: account,
                      audience: [{ type: 'Label', id: label1.id }, { type: 'Label', id: label2.id }])
  end
  let(:twilio_client) { double }
  let(:twilio_messages) { double }

  describe 'perform' do
    before do
      allow(::Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow(twilio_client).to receive(:messages).and_return(twilio_messages)
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
      expect(twilio_messages).to receive(:create).with(
        body: campaign.message,
        messaging_service_sid: twilio_sms.messaging_service_sid,
        to: contact_with_label1.phone_number
      ).once
      expect(twilio_messages).to receive(:create).with(
        body: campaign.message,
        messaging_service_sid: twilio_sms.messaging_service_sid,
        to: contact_with_label2.phone_number
      ).once
      expect(twilio_messages).to receive(:create).with(
        body: campaign.message,
        messaging_service_sid: twilio_sms.messaging_service_sid,
        to: contact_with_both_labels.phone_number
      ).once

      sms_campaign_service.perform
      expect(campaign.reload.completed?).to eq true
    end
  end
end
