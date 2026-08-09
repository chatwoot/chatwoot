require 'rails_helper'

RSpec.describe CampaignRecipient do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:campaign, account: account, inbox: inbox, campaign_type: :one_off, scheduled_at: 1.hour.ago) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }

  describe '#update_from_whatsapp_status!' do
    it 'stores a late delivery timestamp without downgrading a read recipient' do
      read_at = Time.zone.at(1_700_000_700)
      recipient = described_class.create!(account: account, campaign: campaign, inbox: inbox, contact: contact,
                                          status: :read, source_id: 'wamid.read', read_at: read_at)

      recipient.update_from_whatsapp_status!(status: 'delivered', timestamp: 1_700_000_600)

      expect(recipient.reload).to have_attributes(
        status: 'read',
        delivered_at: Time.zone.at(1_700_000_600),
        read_at: read_at
      )
    end
  end
end
