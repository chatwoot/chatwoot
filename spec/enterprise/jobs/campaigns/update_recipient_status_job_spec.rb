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

    described_class.perform_now(inbox.id, 'id' => 'wamid.delayed', 'status' => 'delivered', 'timestamp' => 1_700_000_600)

    expect(recipient.reload).to have_attributes(status: 'delivered', delivered_at: Time.zone.at(1_700_000_600))
  end

  it 'retries when the recipient source ID has not been persisted yet' do
    status = { 'id' => 'wamid.early', 'status' => 'delivered', 'timestamp' => 1_700_000_600 }

    expect do
      described_class.perform_now(inbox.id, status)
    end.to have_enqueued_job(described_class).with(inbox.id, status).on_queue('low')
  end

  it 'does not update a recipient from another inbox' do
    other_account = create(:account)
    other_channel = create(:channel_whatsapp, account: other_account, sync_templates: false, validate_provider_config: false)
    other_campaign = create(:campaign, account: other_account, inbox: other_channel.inbox, campaign_type: :one_off)
    other_recipient = CampaignRecipient.create!(
      account: other_account,
      campaign: other_campaign,
      contact: create(:contact, account: other_account),
      inbox: other_channel.inbox,
      status: :sent,
      source_id: 'wamid.other-inbox'
    )
    status = { 'id' => other_recipient.source_id, 'status' => 'delivered', 'timestamp' => 1_700_000_600 }

    expect do
      described_class.perform_now(inbox.id, status)
    end.to have_enqueued_job(described_class).with(inbox.id, status).on_queue('low')
    expect(other_recipient.reload).to be_sent
  end
end
