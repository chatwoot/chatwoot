require 'rails_helper'

describe Whatsapp::OneoffUnoapiCampaignService do
  subject(:unoapi_campaign_service) { described_class.new(campaign: campaign) }

  let(:account) { create(:account) }
  let!(:unoapi_channel) { create(:channel_whatsapp, provider: 'unoapi', sync_templates: false, validate_provider_config: false) }
  let!(:unoapi_inbox) { create(:inbox, channel: unoapi_channel) }
  let!(:contact) { create(:contact, phone_number: Faker::PhoneNumber.cell_phone_in_e164, account: account) }
  let(:phone_number) { Faker::PhoneNumber.cell_phone_in_e164 }
  let(:uuid) { rand(1..10) }
  let(:audience_1) { { phone_number: phone_number, audience_id: uuid, status: :scheduled } }
  let(:audience_2) { { phone_number: contact.phone_number, audience_id: uuid, status: :scheduled } }
  let(:audience) { [audience_1, audience_2] }
  let!(:campaign) do
    create(:campaign, inbox: unoapi_inbox, account: account, audience: audience)
  end

  describe 'perform' do
    it 'raises error if the campaign is completed' do
      campaign.completed!

      expect { unoapi_campaign_service.perform }.to raise_error 'Completed Campaign'
    end

    it 'raises error invalid campaign when its not a oneoff whatsapp with unoapi provider campaign' do
      whatsapp_channel = create(:channel_whatsapp, sync_templates: false, validate_provider_config: false)
      whatsapp_inbox = create(:inbox, channel: whatsapp_channel)
      campaign = build(:campaign, inbox: whatsapp_inbox)

      expect { described_class.new(campaign: campaign).perform }.to raise_error "Invalid campaign #{campaign.id}"
    end

    it 'send messages to contacts in the audience and marks the campaign completed' do
      allow(CampaignMessageJob).to receive(:perform_later)
      allow(CampaignMessageJob).to receive(:set).and_return(CampaignMessageJob)
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      unoapi_campaign_service.perform
      expect(campaign.reload.completed?).to be true
      expect(CampaignMessageJob)
        .to have_received(:perform_later)
        .with(
          campaign.account_id,
          campaign.inbox_id,
          campaign.id,
          campaign.message,
          audience_1
        )

      expect(CampaignMessageJob)
        .to have_received(:perform_later)
        .with(
          campaign.account_id,
          campaign.inbox_id,
          campaign.id,
          campaign.message,
          audience_2
        )
    end

    it 'send messages to contacts in the audience and wait_for wait_for_seconds' do
      wait_for_seconds = rand(1..10)
      audience_1[:wait_for_seconds] = wait_for_seconds
      campaign.audience = [audience_1]
      service = described_class.new(campaign: campaign)
      allow(CampaignMessageJob).to receive(:set).and_return(CampaignMessageJob)
      allow(CampaignMessageJob).to receive(:perform_later)
      freeze_time do
        service.perform
        expect(CampaignMessageJob)
          .to have_received(:set)
          .with(wait: wait_for_seconds)
      end
    end
  end
end
