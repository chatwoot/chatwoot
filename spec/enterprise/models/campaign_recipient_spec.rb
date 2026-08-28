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

    it 'stores nested provider details when the user-facing error message is blank' do
      recipient = described_class.create!(account: account, campaign: campaign, inbox: inbox, contact: contact,
                                          status: :sent, source_id: 'wamid.failed')

      recipient.update_from_whatsapp_status!(
        status: 'failed',
        timestamp: 1_700_000_800,
        errors: [{ code: 131_044, error_user_msg: '', message: 'Generic error',
                   error_data: { details: 'Business eligibility check failed' } }]
      )

      expect(recipient.reload).to have_attributes(
        status: 'failed',
        error_message: 'Business eligibility check failed'
      )
    end

    it 'does not store a blank provider error message' do
      recipient = described_class.create!(account: account, campaign: campaign, inbox: inbox, contact: contact,
                                          status: :sent, source_id: 'wamid.blank-error')

      recipient.update_from_whatsapp_status!(
        status: 'failed',
        errors: [{ error_user_msg: '', message: '', error_data: { details: '' } }]
      )

      expect(recipient.reload).to have_attributes(status: 'failed', error_message: nil)
    end
  end
end
