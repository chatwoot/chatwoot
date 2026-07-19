require 'rails_helper'

describe CampaignRecipient do
  let(:account) { create(:account) }
  let(:campaign) { create(:campaign, :whatsapp, account: account) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }
  let(:recipient) do
    create(:campaign_recipient, campaign: campaign, account: account, contact: contact, status: :sent, source_id: 'wamid.abc')
  end

  describe '#apply_whatsapp_status!' do
    it 'upgrades to delivered and refreshes campaign stats' do
      recipient.apply_whatsapp_status!(status: 'delivered')

      expect(recipient.reload).to be_delivered
      expect(recipient.delivered_at).to be_present
      expect(campaign.reload.execution_stats['delivered']).to eq(1)
    end

    it 'does not downgrade from read to delivered' do
      recipient.update!(status: :read, read_at: Time.current)
      recipient.apply_whatsapp_status!(status: 'delivered')

      expect(recipient.reload).to be_read
    end

    it 'marks failed with error message' do
      recipient.apply_whatsapp_status!(
        status: 'failed',
        errors: [{ code: 131026, title: 'Message undeliverable' }]
      )

      expect(recipient.reload).to be_failed
      expect(recipient.error_message).to eq('131026: Message undeliverable')
    end
  end
end
