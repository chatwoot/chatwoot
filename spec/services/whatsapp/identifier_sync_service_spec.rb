require 'rails_helper'

RSpec.describe Whatsapp::IdentifierSyncService do
  let(:account) { create(:account) }

  describe '#perform' do
    it 'marks a WhatsApp Cloud BSUID-only visitor as a lead for CRM v2 contact visibility' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                          validate_provider_config: false, sync_templates: false)
      contact = create(:contact, account: account, name: 'BSUID customer', email: nil, phone_number: nil, identifier: nil)
      contact_inbox = create(:contact_inbox, contact: contact, inbox: channel.inbox, source_id: 'IN.2081978709342942')

      described_class.new(contact_inbox: contact_inbox, contact: contact).perform(
        source_ids: ['IN.2081978709342942', 'IN.ENT.9081726354']
      )

      expect(contact.reload).to be_lead
      expect(account.contacts.resolved_contacts(use_crm_v2: true)).to include(contact)
    end

    it 'marks a Twilio WhatsApp BSUID-only visitor as a lead' do
      channel = create(:channel_twilio_sms, :whatsapp, account: account)
      contact = create(:contact, account: account, name: 'Twilio BSUID customer', email: nil, phone_number: nil, identifier: nil)
      contact_inbox = create(:contact_inbox, contact: contact, inbox: channel.inbox, source_id: 'whatsapp:IN.2081978709342942')

      described_class.new(contact_inbox: contact_inbox, contact: contact).perform(
        source_ids: ['whatsapp:IN.2081978709342942']
      )

      expect(contact.reload).to be_lead
    end

    it 'does not mark a visitor as a lead for non-BSUID WhatsApp source ids' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account,
                                          validate_provider_config: false, sync_templates: false)
      contact = create(:contact, account: account, name: 'Phone customer', email: nil, phone_number: nil, identifier: nil)
      contact_inbox = create(:contact_inbox, contact: contact, inbox: channel.inbox, source_id: '919745786257')

      described_class.new(contact_inbox: contact_inbox, contact: contact).perform(
        source_ids: ['919745786257']
      )

      expect(contact.reload).to be_visitor
    end
  end
end
