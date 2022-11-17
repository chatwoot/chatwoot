require 'rails_helper'

describe ::ContactInboxWithContactBuilder do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, email: 'xyc@example.com', phone_number: '+23423424123', account: account, identifier: '123') }
  let(:existing_contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

  describe '#perform' do
    it 'doesnot create contact if it already exist with source id' do
      contact_inbox = described_class.new(
        source_id: existing_contact_inbox.source_id,
        inbox: inbox,
        contact_attributes: {
          name: 'Contact',
          phone_number: '+1234567890',
          email: 'testemail@example.com'
        }
      ).perform

      expect(contact_inbox.contact.id).to be(contact.id)
    end

    it 'creates contact if contact doesnot exist with source id' do
      contact_inbox = described_class.new(
        source_id: '123456',
        inbox: inbox,
        contact_attributes: {
          name: 'Contact',
          phone_number: '+1234567890',
          email: 'testemail@example.com',
          custom_attributes: { test: 'test' }
        }
      ).perform

      expect(contact_inbox.contact.id).not_to eq(contact.id)
      expect(contact_inbox.contact.name).to eq('Contact')
      expect(contact_inbox.contact.custom_attributes).to eq({ 'test' => 'test' })
      expect(contact_inbox.inbox_id).to eq(inbox.id)
    end

    it 'doesnot create contact if it already exist with identifier' do
      contact_inbox = described_class.new(
        source_id: '123456',
        inbox: inbox,
        contact_attributes: {
          name: 'Contact',
          identifier: contact.identifier,
          phone_number: contact.phone_number,
          email: 'testemail@example.com'
        }
      ).perform

      expect(contact_inbox.contact.id).to be(contact.id)
    end

    it 'doesnot create contact if it already exist with email' do
      contact_inbox = described_class.new(
        source_id: '123456',
        inbox: inbox,
        contact_attributes: {
          name: 'Contact',
          phone_number: '+1234567890',
          email: contact.email
        }
      ).perform

      expect(contact_inbox.contact.id).to be(contact.id)
    end

    it 'doesnot create contact when an uppercase email is passed for an already existing contact email' do
      contact_inbox = described_class.new(
        source_id: '123456',
        inbox: inbox,
        contact_attributes: {
          name: 'Contact',
          phone_number: '+1234567890',
          email: contact.email.upcase
        }
      ).perform

      expect(contact_inbox.contact.id).to be(contact.id)
    end

    it 'doesnot create contact if it already exist with phone number' do
      contact_inbox = described_class.new(
        source_id: '123456',
        inbox: inbox,
        contact_attributes: {
          name: 'Contact',
          phone_number: contact.phone_number,
          email: 'testemail@example.com'
        }
      ).perform

      expect(contact_inbox.contact.id).to be(contact.id)
    end
  end
end
