require 'rails_helper'

RSpec.describe Campaigns::UpdateRecipientStatusJob do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:campaign, account: account, inbox: inbox, campaign_type: :one_off, scheduled_at: 1.hour.ago) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }

  it 'updates the recipient after its provider source ID is persisted' do
    recipient = CampaignRecipient.create!(account: account, campaign: campaign, inbox: inbox, contact: contact,
                                          status: :sent, source_id: 'wamid.delayed')

    described_class.perform_now('id' => 'wamid.delayed', 'status' => 'delivered', 'timestamp' => 1_700_000_600)

    expect(recipient.reload).to have_attributes(status: 'delivered', delivered_at: Time.zone.at(1_700_000_600))
  end
end
