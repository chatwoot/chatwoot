require 'rails_helper'

RSpec.describe ContactInbox, type: :model do
  describe 'WhatsApp Group JID validation' do
    let(:whatsapp_web_inbox) { create(:channel_whatsapp, provider: 'whatsapp_web', sync_templates: false, validate_provider_config: false).inbox }
    let(:contact) { create(:contact) }

    context 'with valid group JIDs' do
      it 'allows valid group JIDs for whatsapp_web provider' do
        valid_group_jids = [
          '120363025246125486@g.us',
          '1234567890@g.us',
          '123456789012345678@g.us'
        ]

        valid_group_jids.each do |jid|
          contact_inbox = build(:contact_inbox, contact: contact, inbox: whatsapp_web_inbox, source_id: jid)
          expect(contact_inbox.valid?).to be(true), "Expected #{jid} to be valid"
        end
      end
    end

    context 'with invalid group JIDs' do
      it 'rejects invalid group JIDs' do
        invalid_group_jids = [
          '123456789@s.whatsapp.net', # wrong suffix
          '123456789@g.us.invalid', # extra suffix
          'abc123456789@g.us', # contains letters
          '12345678@g.us', # too short (less than 10 digits)
          '1234567890123456789@g.us' # too long (more than 18 digits)
        ]

        invalid_group_jids.each do |jid|
          contact_inbox = build(:contact_inbox, contact: contact, inbox: whatsapp_web_inbox, source_id: jid)
          expect(contact_inbox.valid?).to be(false), "Expected #{jid} to be invalid"
        end
      end
    end

    context 'with regular WhatsApp provider' do
      let(:whatsapp_cloud_inbox) do
        create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false).inbox
      end

      it 'does not allow group JIDs for non-whatsapp_web providers' do
        group_jid = '120363025246125486@g.us'
        contact_inbox = build(:contact_inbox, contact: contact, inbox: whatsapp_cloud_inbox,
                                              source_id: group_jid)
        expect(contact_inbox.valid?).to be(false)
        expect(contact_inbox.errors.full_messages.first).to include('invalid source id')
      end
    end

    context 'with individual WhatsApp Web JIDs' do
      it 'allows valid individual JIDs for whatsapp_web provider' do
        valid_individual_jids = [
          '5511999887766@s.whatsapp.net',
          '1234567890@s.whatsapp.net',
          '123456789012345@s.whatsapp.net'
        ]

        valid_individual_jids.each do |jid|
          contact_inbox = build(:contact_inbox, contact: contact, inbox: whatsapp_web_inbox, source_id: jid)
          expect(contact_inbox.valid?).to be(true), "Expected #{jid} to be valid"
        end
      end
    end
  end
end
