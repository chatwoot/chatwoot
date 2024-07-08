require 'rails_helper'

describe Api::OneoffApiCampaignService do
  subject(:api_campaign_service) { described_class.new(campaign: campaign) }

  let(:account) { create(:account) }
  let!(:api_channel) { create(:channel_api) }
  let!(:api_inbox) { create(:inbox, channel: api_channel) }
  let(:label1) { create(:label, account: account) }
  let(:label2) { create(:label, account: account) }
  let(:event_name) { :'message.created' }
  let!(:campaign) do
    create(
      :campaign,
      inbox: api_inbox,
      account: account,
      audience: [
        { type: 'Label', id: label1.id },
        { type: 'Label', id: label2.id }
      ]
    )
  end

  describe 'perform' do
    it 'raises error if the campaign is completed' do
      campaign.completed!

      expect { api_campaign_service.perform }.to raise_error 'Completed Campaign'
    end

    it 'raises error invalid campaign when its not a oneoff API campaign' do
      campaign = create(:campaign)

      expect { described_class.new(campaign: campaign).perform }.to raise_error "Invalid campaign #{campaign.id}"
    end

    it 'send messages to contacts in the audience and marks the campaign completed' do
      contact_with_label1, contact_with_label2, contact_with_both_labels = FactoryBot.create_list(:contact, 3, :with_phone_number, account: account)
      contact_with_label1.update_labels([label1.title])
      contact_with_label2.update_labels([label2.title])
      contact_with_both_labels.update_labels([label1.title, label2.title])

      webhook_listener = WebhookListener.instance
      api_campaign_service.perform
      campaign.conversations.each do |conversation|
        api_event = Events::Base.new(event_name, Time.zone.now, message: conversation.messages.last)
        webhook_listener.message_created(api_event)
      end
      expect(campaign.reload.completed?).to be true
      expect(campaign.conversations.length).to eq(3)
    end
  end
end
