require 'rails_helper'

describe Whatsapp::ContactInboxConsolidationService do
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:phone) { '5511998765432' }
  let(:lid) { '12345678' }
  let(:identifier) { "#{lid}@lid" }

  describe '#perform' do
    context 'when phone is blank' do
      it 'does nothing' do
        service = described_class.new(inbox: inbox, phone: nil, lid: lid, identifier: identifier)

        expect { service.perform }.not_to change(ContactInbox, :count)
      end
    end

    context 'when lid is blank' do
      it 'does nothing' do
        service = described_class.new(inbox: inbox, phone: phone, lid: nil, identifier: identifier)

        expect { service.perform }.not_to change(ContactInbox, :count)
      end
    end

    context 'when phone and lid are the same' do
      it 'does nothing' do
        contact = create(:contact, account: inbox.account, phone_number: "+#{phone}")
        create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone)

        service = described_class.new(inbox: inbox, phone: phone, lid: phone, identifier: identifier)

        expect { service.perform }.not_to change(ContactInbox, :count)
      end
    end

    context 'when no phone-based contact_inbox exists' do
      it 'does nothing when no contacts exist' do
        service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)

        expect { service.perform }.not_to change(ContactInbox, :count)
      end
    end

    context 'when contact exists by phone but has no contact_inbox in this inbox' do
      let!(:phone_contact) { create(:contact, account: inbox.account, phone_number: "+#{phone}") }

      context 'when another contact has the target identifier (provider conversion scenario)' do
        let!(:lid_contact) { create(:contact, account: inbox.account, identifier: identifier) }

        it 'transfers identifier from the conflicting contact to the phone contact' do
          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          expect(phone_contact.reload.identifier).to eq(identifier)
          expect(lid_contact.reload.identifier).to be_nil
        end
      end

      context 'when another contact has the identifier AND a lid contact_inbox in this inbox' do
        let!(:lid_contact) { create(:contact, account: inbox.account, identifier: identifier) }
        let!(:lid_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: lid_contact, source_id: lid) }

        it 'adopts the lid contact_inbox, reassigns messages, and transfers it to the phone contact' do
          lid_conversation = create(:conversation, inbox: inbox, contact: lid_contact, contact_inbox: lid_contact_inbox)
          lid_message = create(:message, conversation: lid_conversation, sender: lid_contact, inbox: inbox, account: inbox.account)

          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          expect(lid_contact_inbox.reload.contact_id).to eq(phone_contact.id)
          expect(phone_contact.reload.identifier).to eq(identifier)
          expect(lid_conversation.reload.contact_id).to eq(phone_contact.id)
          expect(lid_message.reload.sender).to eq(phone_contact)
          expect(Contact.exists?(lid_contact.id)).to be(false)
        end
      end

      context 'when no identifier conflict exists' do
        it 'does not change contacts' do
          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          expect(phone_contact.reload.identifier).to be_nil
        end
      end
    end

    context 'when only phone-based contact_inbox exists' do
      let!(:contact) { create(:contact, account: inbox.account, phone_number: "+#{phone}") }
      let!(:phone_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone) }

      it 'migrates the contact_inbox from phone to lid' do
        service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
        service.perform

        expect(phone_contact_inbox.reload.source_id).to eq(lid)
        expect(contact.reload.identifier).to eq(identifier)
        expect(contact.phone_number).to eq("+#{phone}")
      end

      context 'when there is an identifier conflict with a different contact' do
        let!(:conflicting_contact) { create(:contact, account: inbox.account, identifier: identifier) }

        it 'resolves the conflict and migrates' do
          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          expect(phone_contact_inbox.reload.source_id).to eq(lid)
          expect(contact.reload.identifier).to eq(identifier)
          expect(conflicting_contact.reload.identifier).to be_nil
        end
      end

      context 'when there is a phone conflict with a different contact' do
        it 'does not migrate when another contact already has this phone number' do
          # Create contact without phone, then create conflicting contact with the phone
          contact.update!(phone_number: nil)
          create(:contact, account: inbox.account, phone_number: "+#{phone}")

          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          expect(phone_contact_inbox.reload.source_id).to eq(phone)
        end
      end
    end

    context 'when both phone and lid contact_inboxes exist for the same contact' do
      let!(:contact) { create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: identifier) }
      let!(:lid_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid) }
      let!(:phone_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: phone) }

      it 'consolidates by moving conversations and deleting phone-based contact_inbox' do
        conversation = create(:conversation, inbox: inbox, contact: contact, contact_inbox: phone_contact_inbox)

        service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
        service.perform

        expect(conversation.reload.contact_inbox_id).to eq(lid_contact_inbox.id)
        expect(ContactInbox.exists?(phone_contact_inbox.id)).to be(false)
        expect(inbox.contact_inboxes.where(contact: contact).count).to eq(1)
      end

      it 'handles multiple conversations on the phone-based contact_inbox' do
        conversation1 = create(:conversation, inbox: inbox, contact: contact, contact_inbox: phone_contact_inbox)
        conversation2 = create(:conversation, inbox: inbox, contact: contact, contact_inbox: phone_contact_inbox)
        conversation3 = create(:conversation, inbox: inbox, contact: contact, contact_inbox: lid_contact_inbox)

        service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
        service.perform

        expect(conversation1.reload.contact_inbox_id).to eq(lid_contact_inbox.id)
        expect(conversation2.reload.contact_inbox_id).to eq(lid_contact_inbox.id)
        expect(conversation3.reload.contact_inbox_id).to eq(lid_contact_inbox.id)
        expect(ContactInbox.exists?(phone_contact_inbox.id)).to be(false)
      end
    end

    context 'when phone and lid contact_inboxes belong to different contacts' do
      let!(:phone_contact) { create(:contact, account: inbox.account, phone_number: "+#{phone}", name: 'Brigita Pinto') }
      let!(:lid_contact) { create(:contact, account: inbox.account, identifier: identifier, name: lid) }
      let!(:phone_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: phone_contact, source_id: phone) }
      let!(:lid_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: lid_contact, source_id: lid) }

      it 'merges into the phone contact and consolidates contact_inboxes' do
        lid_conversation = create(:conversation, inbox: inbox, contact: lid_contact, contact_inbox: lid_contact_inbox)

        service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
        service.perform

        # LID contact_inbox is destroyed, phone contact_inbox gets LID source_id
        expect(ContactInbox.exists?(lid_contact_inbox.id)).to be(false)
        expect(phone_contact_inbox.reload.source_id).to eq(lid)

        # Phone contact becomes the canonical contact with LID identifier
        expect(phone_contact.reload.identifier).to eq(identifier)

        # Orphaned LID contact is destroyed
        expect(Contact.exists?(lid_contact.id)).to be(false)

        # Conversation is moved to the phone contact
        expect(lid_conversation.reload.contact_id).to eq(phone_contact.id)
        expect(lid_conversation.contact_inbox_id).to eq(phone_contact_inbox.id)
      end

      it 'handles multiple conversations across both contact_inboxes' do
        phone_conversation = create(:conversation, inbox: inbox, contact: phone_contact, contact_inbox: phone_contact_inbox)
        lid_conversation1 = create(:conversation, inbox: inbox, contact: lid_contact, contact_inbox: lid_contact_inbox)
        lid_conversation2 = create(:conversation, inbox: inbox, contact: lid_contact, contact_inbox: lid_contact_inbox)

        service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
        service.perform

        # Phone conversation stays on phone contact
        expect(phone_conversation.reload.contact_id).to eq(phone_contact.id)
        expect(phone_conversation.contact_inbox_id).to eq(phone_contact_inbox.id)

        # LID conversations are moved to phone contact
        expect(lid_conversation1.reload.contact_id).to eq(phone_contact.id)
        expect(lid_conversation1.contact_inbox_id).to eq(phone_contact_inbox.id)
        expect(lid_conversation2.reload.contact_id).to eq(phone_contact.id)
        expect(lid_conversation2.contact_inbox_id).to eq(phone_contact_inbox.id)

        expect(inbox.contact_inboxes.where(contact: phone_contact).count).to eq(1)
      end
    end

    context 'when contact exists by phone but has contact_inbox with different source_id' do
      let!(:contact) { create(:contact, account: inbox.account, phone_number: "+#{phone}") }
      let!(:old_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '999999999') }

      it 'updates the existing contact_inbox source_id to lid' do
        service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)

        expect { service.perform }.not_to change(ContactInbox, :count)

        expect(old_contact_inbox.reload.source_id).to eq(lid)
        expect(contact.reload.identifier).to eq(identifier)
      end

      context 'when a lid contact_inbox already exists for the same contact' do
        let!(:lid_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: lid) } # rubocop:disable RSpec/LetSetup

        it 'does not update to avoid duplicate' do
          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          expect(old_contact_inbox.reload.source_id).to eq('999999999')
        end
      end

      context 'when a lid contact_inbox exists for a different contact' do
        let!(:lid_contact) { create(:contact, account: inbox.account, identifier: identifier, name: lid) }
        let!(:lid_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: lid_contact, source_id: lid) }

        it 'consolidates by merging into the phone contact' do
          lid_conversation = create(:conversation, inbox: inbox, contact: lid_contact, contact_inbox: lid_contact_inbox)

          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          # LID contact_inbox destroyed, old contact_inbox updated to LID source_id
          expect(ContactInbox.exists?(lid_contact_inbox.id)).to be(false)
          expect(old_contact_inbox.reload.source_id).to eq(lid)

          # Phone contact becomes canonical
          expect(contact.reload.identifier).to eq(identifier)

          # Orphaned LID contact is destroyed
          expect(Contact.exists?(lid_contact.id)).to be(false)

          # Conversation moved to phone contact
          expect(lid_conversation.reload.contact_id).to eq(contact.id)
          expect(lid_conversation.contact_inbox_id).to eq(old_contact_inbox.id)
        end
      end

      context 'when another contact already has the same identifier' do
        let!(:conflicting_contact) { create(:contact, account: inbox.account, identifier: identifier) }

        it 'resolves the conflict and updates' do
          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)
          service.perform

          expect(old_contact_inbox.reload.source_id).to eq(lid)
          expect(contact.reload.identifier).to eq(identifier)
          expect(conflicting_contact.reload.identifier).to be_nil
        end
      end
    end

    context 'when the stored phone carries the Brazilian ninth digit and the webhook delivers the canonical number without it' do
      let(:phone) { '551198765432' }
      let(:stored_phone) { '5511998765432' }

      context 'when a phone-based contact_inbox exists under the other variant' do
        let!(:contact) { create(:contact, account: inbox.account, phone_number: "+#{stored_phone}") }
        let!(:phone_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: stored_phone) }

        it 'migrates the contact_inbox to lid and aligns the phone to the canonical number' do
          service = described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier)

          expect { service.perform }.not_to change(ContactInbox, :count)

          expect(phone_contact_inbox.reload.source_id).to eq(lid)
          expect(contact.reload.identifier).to eq(identifier)
          expect(contact.phone_number).to eq("+#{phone}")
        end

        it 'prefers an exact source_id match over a variant' do
          exact_contact = create(:contact, account: inbox.account, phone_number: "+#{phone}")
          exact_contact_inbox = create(:contact_inbox, inbox: inbox, contact: exact_contact, source_id: phone)

          described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier).perform

          expect(exact_contact_inbox.reload.source_id).to eq(lid)
          expect(phone_contact_inbox.reload.source_id).to eq(stored_phone)
        end

        it 'merges a duplicate lid contact created by a previous reply back into the variant phone contact' do
          lid_contact = create(:contact, account: inbox.account, phone_number: "+#{phone}", identifier: identifier, name: lid)
          lid_contact_inbox = create(:contact_inbox, inbox: inbox, contact: lid_contact, source_id: lid)
          lid_conversation = create(:conversation, inbox: inbox, contact: lid_contact, contact_inbox: lid_contact_inbox)

          described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier).perform

          expect(ContactInbox.exists?(lid_contact_inbox.id)).to be(false)
          expect(Contact.exists?(lid_contact.id)).to be(false)
          expect(phone_contact_inbox.reload.source_id).to eq(lid)
          expect(contact.reload.identifier).to eq(identifier)
          expect(contact.phone_number).to eq("+#{phone}")
          expect(lid_conversation.reload.contact_id).to eq(contact.id)
          expect(lid_conversation.contact_inbox_id).to eq(phone_contact_inbox.id)
        end
      end

      context 'when the contact exists under the other variant without a phone-based contact_inbox' do
        let!(:contact) { create(:contact, account: inbox.account, phone_number: "+#{stored_phone}") }
        let!(:old_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '999999999') }

        it 'updates the existing contact_inbox source_id to lid' do
          described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier).perform

          expect(old_contact_inbox.reload.source_id).to eq(lid)
          expect(contact.reload.identifier).to eq(identifier)
        end
      end
    end

    context 'when the stored phone misses the Brazilian ninth digit and the webhook delivers it' do
      let(:phone) { '5511998765432' }
      let(:stored_phone) { '551198765432' }

      let!(:contact) { create(:contact, account: inbox.account, phone_number: "+#{stored_phone}") }
      let!(:phone_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: stored_phone) }

      it 'migrates the contact_inbox to lid and aligns the phone to the canonical number' do
        described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier).perform

        expect(phone_contact_inbox.reload.source_id).to eq(lid)
        expect(contact.reload.phone_number).to eq("+#{phone}")
      end
    end

    context 'when the stored phone is the Argentinian mobile form and the webhook delivers the number without the 9' do
      let(:phone) { '541112345678' }
      let(:stored_phone) { '5491112345678' }

      let!(:contact) { create(:contact, account: inbox.account, phone_number: "+#{stored_phone}") }
      let!(:phone_contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: stored_phone) }

      # A 54 number without the 9 is a valid landline of its own, so the two forms are not one line:
      # synthesizing the 549 alias here could answer a landline through a different subscriber's thread.
      it 'leaves the contact stored under the mobile form alone' do
        described_class.new(inbox: inbox, phone: phone, lid: lid, identifier: identifier).perform

        expect(phone_contact_inbox.reload.source_id).to eq(stored_phone)
        expect(contact.reload.phone_number).to eq("+#{stored_phone}")
      end
    end
  end
end
