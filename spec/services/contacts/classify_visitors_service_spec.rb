require 'rails_helper'

RSpec.describe Contacts::ClassifyVisitorsService do
  subject(:classify) { described_class.new(from_id: Contact.minimum(:id), to_id: Contact.maximum(:id)).perform }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  # the widget names an anonymous visitor like this, and a visitor this old is past the retention period
  let(:anonymous) { { account: account, name: 'quiet-fog-31', created_at: 60.days.ago } }

  describe 'a visitor that becomes a lead' do
    it 'has an identity that was stored without running the save callbacks' do
      Contact.import([build(:contact, **anonymous, identifier: 'user-1')])
      contact = account.contacts.find_by!(identifier: 'user-1')

      expect { classify }.to change { contact.reload.contact_type }.from('visitor').to('lead')
    end

    it 'has a conversation' do
      contact = create(:contact, **anonymous)
      create(:conversation, account: account, inbox: inbox, contact: contact)
      Contact.connection.exec_update("UPDATE contacts SET contact_type = 0 WHERE id = #{contact.id}")

      expect { classify }.to change { contact.reload.contact_type }.from('visitor').to('lead')
    end

    it 'has a social attribute with a value' do
      Contact.import([build(:contact, **anonymous, additional_attributes: { social_telegram_user_id: '42' })])
      contact = account.contacts.last

      expect { classify }.to change { contact.reload.contact_type }.from('visitor').to('lead')
    end

    it 'sent a message once, even when its conversation is gone' do
      contact = create(:contact, **anonymous, last_activity_at: 50.days.ago)

      expect { classify }.to change { contact.reload.contact_type }.from('visitor').to('lead')
    end

    it 'has a name that someone gave it' do
      contact = create(:contact, **anonymous, name: 'Maria Lopez')

      expect { classify }.to change { contact.reload.contact_type }.from('visitor').to('lead')
    end

    it 'has a note' do
      contact = create(:contact, **anonymous)
      create(:note, account: account, contact: contact)

      expect { classify }.to change { contact.reload.contact_type }.from('visitor').to('lead')
    end

    it 'has a label' do
      contact = create(:contact, **anonymous)
      contact.update!(label_list: ['vip'])

      expect { classify }.to change { contact.reload.contact_type }.from('visitor').to('lead')
    end

    it 'does not change updated_at' do
      contact = create(:contact, **anonymous, name: 'Maria Lopez', updated_at: 60.days.ago)

      expect { classify }.not_to(change { contact.reload.updated_at })
    end
  end

  describe 'a stale visitor' do
    it 'is deleted with its contact inbox' do
      contact = create(:contact, **anonymous)
      contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)

      expect(classify).to include(purged: 1)
      expect(Contact.exists?(contact.id)).to be(false)
      expect(ContactInbox.exists?(contact_inbox.id)).to be(false)
    end

    it 'is kept while it is online in the widget' do
      contact = create(:contact, **anonymous)
      OnlineStatusTracker.update_presence(account.id, 'Contact', contact.id)

      expect { classify }.not_to change(Contact, :count)
      expect(contact.reload).to be_visitor
    end

    it 'is deleted when its social attribute has no value' do
      Contact.import([build(:contact, **anonymous, additional_attributes: { social_profiles: {} })])

      expect { classify }.to change(Contact, :count).by(-1)
    end
  end

  describe 'a contact that is left alone' do
    it 'is a visitor younger than the retention period' do
      contact = create(:contact, **anonymous, created_at: 5.days.ago)

      expect { classify }.not_to change(Contact, :count)
      expect(contact.reload).to be_visitor
    end

    it 'has an identifier made of spaces, which the contact list still shows' do
      Contact.import([build(:contact, **anonymous, identifier: '   ')])
      contact = account.contacts.last

      expect { classify }.not_to change(Contact, :count)
      expect(contact.reload).to be_visitor
    end

    it 'is already a lead or a customer' do
      lead = create(:contact, **anonymous, contact_type: :lead)
      customer = create(:contact, **anonymous, contact_type: :customer)

      expect { classify }.not_to change(Contact, :count)
      expect([lead.reload, customer.reload].map(&:contact_type)).to eq(%w[lead customer])
    end
  end
end
