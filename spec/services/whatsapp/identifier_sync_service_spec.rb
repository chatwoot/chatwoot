require 'rails_helper'

describe Whatsapp::IdentifierSyncService do
  let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let(:inbox) { whatsapp_channel.inbox }
  let(:contact_inbox) { create(:contact_inbox, inbox: inbox, source_id: '2423423243') }
  let(:contact) { contact_inbox.contact }

  def sync(source_ids)
    described_class.new(contact_inbox: contact_inbox, contact: contact).perform(source_ids: source_ids)
  end

  describe '#perform' do
    it 'mirrors the business scoped user id onto the contact' do
      sync(['2423423243', 'IN.2081978709342942'])

      expect(contact.reload.additional_attributes['whatsapp_bsuid']).to eq('IN.2081978709342942')
    end

    it 'reports the parent identifier next to the regular one' do
      sync(['2423423243', 'IN.2081978709342942', 'IN.ENT.9081726354'])

      expect(contact.reload.additional_attributes).to include(
        'whatsapp_bsuid' => 'IN.2081978709342942',
        'whatsapp_bsuid_parent' => 'IN.ENT.9081726354'
      )
    end

    it 'falls back to the parent identifier when it is the only one available' do
      sync(['2423423243', 'IN.ENT.9081726354'])

      expect(contact.reload.additional_attributes['whatsapp_bsuid']).to eq('IN.ENT.9081726354')
    end

    it 'keeps the identifier reachable through the webhook payload' do
      sync(['2423423243', 'IN.2081978709342942'])

      expect(contact.reload.webhook_data[:additional_attributes]).to include('whatsapp_bsuid' => 'IN.2081978709342942')
      expect(contact.push_event_data[:additional_attributes]).to include('whatsapp_bsuid' => 'IN.2081978709342942')
    end

    it 'preserves attributes written by other syncs' do
      contact.update!(additional_attributes: { 'company_name' => 'Acme' })

      sync(['2423423243', 'IN.2081978709342942'])

      expect(contact.reload.additional_attributes).to include(
        'company_name' => 'Acme',
        'whatsapp_bsuid' => 'IN.2081978709342942'
      )
    end

    it 'does not write anything when the payload carries no business scoped user id' do
      expect { sync(['2423423243']) }.not_to change { contact.reload.additional_attributes }
    end

    it 'does not touch the contact when the identifier is already mirrored' do
      sync(['2423423243', 'IN.2081978709342942'])

      expect { sync(['2423423243', 'IN.2081978709342942']) }.not_to change { contact.reload.updated_at }
    end
  end
end
