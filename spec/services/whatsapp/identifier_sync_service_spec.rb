require 'rails_helper'

RSpec.describe Whatsapp::IdentifierSyncService do
  let(:account) { create(:account) }
  let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '2423423243') }
  let(:contact) { contact_inbox.contact }
  let(:service) { described_class.new(contact_inbox: contact_inbox, contact: contact) }

  describe '#perform' do
    it 'mirrors the business scoped user id onto the contact' do
      service.perform(source_ids: ['2423423243', 'IN.2081978709342942'])

      expect(contact.reload.additional_attributes['whatsapp_bsuid']).to eq('IN.2081978709342942')
    end

    it 'reports the parent identifier next to the regular one' do
      service.perform(source_ids: ['2423423243', 'IN.2081978709342942', 'IN.ENT.9081726354'])

      expect(contact.reload.additional_attributes).to include(
        'whatsapp_bsuid' => 'IN.2081978709342942',
        'whatsapp_bsuid_parent' => 'IN.ENT.9081726354'
      )
    end

    it 'falls back to the parent identifier when it is the only one available' do
      service.perform(source_ids: ['2423423243', 'IN.ENT.9081726354'])

      expect(contact.reload.additional_attributes['whatsapp_bsuid']).to eq('IN.ENT.9081726354')
    end

    it 'does not replace the mirrored identifier when a later payload carries only the parent' do
      service.perform(source_ids: ['2423423243', 'IN.2081978709342942', 'IN.ENT.9081726354'])

      service.perform(source_ids: ['IN.ENT.9081726354'])

      expect(contact.reload.additional_attributes).to include(
        'whatsapp_bsuid' => 'IN.2081978709342942',
        'whatsapp_bsuid_parent' => 'IN.ENT.9081726354'
      )
    end

    it 'replaces a mirrored parent identifier when the parent rotates' do
      service.perform(source_ids: ['2423423243', 'IN.ENT.9081726354'])

      service.perform(source_ids: ['2423423243', 'IN.ENT.7263540192'])

      expect(contact.reload.additional_attributes).to include(
        'whatsapp_bsuid' => 'IN.ENT.7263540192',
        'whatsapp_bsuid_parent' => 'IN.ENT.7263540192'
      )
    end

    it 'does not mirror an identifier that another contact already owns' do
      other = create(:contact, account: whatsapp_channel.inbox.account)
      create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: other, source_id: 'IN.2081978709342942')

      service.perform(source_ids: ['2423423243', 'IN.2081978709342942', 'IN.ENT.9081726354'])

      expect(contact.reload.additional_attributes).not_to include('whatsapp_bsuid' => 'IN.2081978709342942')
      expect(whatsapp_channel.inbox.contact_inboxes.find_by(source_id: 'IN.2081978709342942').contact).to eq(other)
    end

    it 'keeps the identifier reachable through the webhook payload' do
      service.perform(source_ids: ['2423423243', 'IN.2081978709342942'])
      contact.reload

      expect(contact.webhook_data[:additional_attributes]).to include('whatsapp_bsuid' => 'IN.2081978709342942')
      expect(contact.push_event_data[:additional_attributes]).to include('whatsapp_bsuid' => 'IN.2081978709342942')
    end

    it 'preserves attributes written by other syncs' do
      contact.update!(additional_attributes: { 'company_name' => 'Acme' })

      service.perform(source_ids: ['2423423243', 'IN.2081978709342942'])

      expect(contact.reload.additional_attributes).to include(
        'company_name' => 'Acme',
        'whatsapp_bsuid' => 'IN.2081978709342942'
      )
    end

    it 'does not write anything when the payload carries no business scoped user id' do
      expect { service.perform(source_ids: ['2423423243']) }.not_to(change { contact.reload.additional_attributes })
    end

    it 'does not touch the contact when the identifier is already mirrored' do
      service.perform(source_ids: ['2423423243', 'IN.2081978709342942'])

      expect { service.perform(source_ids: ['2423423243', 'IN.2081978709342942']) }.not_to(change { contact.reload.updated_at })
    end

    context 'when the inbox is a twilio whatsapp one' do
      let!(:twilio_channel) { create(:channel_twilio_sms, medium: :whatsapp) }
      let(:contact_inbox) { create(:contact_inbox, inbox: twilio_channel.inbox, source_id: 'whatsapp:+12345678900') }

      it 'reports the identifier without the channel prefix' do
        service.perform(source_ids: ['whatsapp:+12345678900', 'whatsapp:IN.2081978709342942', 'whatsapp:IN.ENT.9081726354'])

        expect(contact.reload.additional_attributes).to include(
          'whatsapp_bsuid' => 'IN.2081978709342942',
          'whatsapp_bsuid_parent' => 'IN.ENT.9081726354'
        )
      end
    end

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
