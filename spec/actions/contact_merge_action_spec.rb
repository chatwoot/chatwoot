require 'rails_helper'

describe ContactMergeAction do
  subject(:contact_merge) { described_class.new(account: account, base_contact: base_contact, mergee_contact: mergee_contact).perform }

  let!(:account) { create(:account) }
  let!(:base_contact) do
    create(:contact, identifier: 'base_contact', email: 'old@old.com', phone_number: '', custom_attributes: { val_test: 'old', val_empty_old: '' },
                     account: account)
  end
  let!(:mergee_contact) do
    create(:contact, identifier: '', email: 'new@new.com', phone_number: '+12212345',
                     custom_attributes: { val_test: 'new', val_new: 'new', val_empty_new: '' }, account: account)
  end

  before do
    2.times.each do
      create(:conversation, contact: base_contact)
      create(:conversation, contact: mergee_contact)
      create(:message, sender: mergee_contact)
      create(:note, contact: mergee_contact, account: mergee_contact.account)
    end
  end

  describe '#perform' do
    it 'deletes mergee_contact' do
      contact_merge
      expect { mergee_contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'copies information from mergee contact to base contact' do
      contact_merge
      base_contact.reload
      expect(base_contact.identifier).to eq('base_contact')
      expect(base_contact.email).to eq('old@old.com')
      expect(base_contact.phone_number).to eq('+12212345')
      expect(base_contact.custom_attributes['val_test']).to eq('old')
      expect(base_contact.custom_attributes['val_new']).to eq('new')
      expect(base_contact.custom_attributes['val_empty_old']).to eq('')
      expect(base_contact.custom_attributes['val_empty_new']).to eq('')
    end

    context 'when base contact and merge contact are same' do
      it 'does not delete contact' do
        mergee_contact = base_contact
        contact_merge
        expect(mergee_contact.reload).not_to be_nil
      end
    end

    context 'when mergee contact has conversations' do
      it 'moves the conversations to base contact' do
        contact_merge
        expect(base_contact.conversations.count).to be 4
      end
    end

    context 'when mergee contact has contact inboxes' do
      it 'moves the contact inboxes to base contact' do
        contact_merge
        expect(base_contact.contact_inboxes.count).to be 4
      end
    end

    context 'when mergee contact has messages' do
      it 'moves the messages to base contact' do
        contact_merge
        expect(base_contact.messages.count).to be 2
      end
    end

    context 'when mergee contact has notes' do
      it 'moves the notes to base contact' do
        expect(base_contact.notes.count).to be 0
        expect(mergee_contact.notes.count).to be 2

        contact_merge

        expect(base_contact.reload.notes.count).to be 2
      end
    end

    context 'when mergee contact has a higher contact type' do
      let(:mergee_contact) { create(:contact, account: account, email: 'new@new.com', contact_type: :customer) }

      it 'keeps the higher contact type on base contact' do
        contact_merge
        expect(base_contact.reload).to be_customer
      end
    end

    context 'when a trusted source has verified values of the contacts' do
      def verify(contact, attributes)
        contact.assign_verified_attributes(attributes, source: 'jwt')
        contact.save!
      end

      it 'takes a verified value of the mergee contact over an unverified value of the base contact' do
        verify(mergee_contact, email: 'new@new.com')

        contact_merge

        expect(base_contact.reload.email).to eq('new@new.com')
        expect(base_contact.verified_attributes).to eq('email' => 'jwt')
      end

      it 'keeps a verified value of the base contact over an unverified value of the mergee contact' do
        verify(base_contact, email: 'old@old.com')

        contact_merge

        expect(base_contact.reload.email).to eq('old@old.com')
        expect(base_contact.verified_attributes).to eq('email' => 'jwt')
      end

      it 'keeps the value of the base contact when both values are verified' do
        verify(base_contact, email: 'old@old.com')
        verify(mergee_contact, email: 'new@new.com')

        contact_merge

        expect(base_contact.reload.email).to eq('old@old.com')
        expect(base_contact.verified_attributes).to eq('email' => 'jwt')
      end

      it 'keeps the value of the base contact when neither value is verified' do
        contact_merge

        expect(base_contact.reload.email).to eq('old@old.com')
        expect(base_contact.verified_attributes).to eq({})
      end

      it 'does not mark a value that the base contact takes from an unverified mergee contact' do
        contact_merge

        expect(base_contact.reload.phone_number).to eq('+12212345')
        expect(base_contact.attribute_verified?(:phone_number)).to be(false)
      end
    end

    context 'when contacts belong to a different account' do
      it 'throws an exception' do
        new_account = create(:account)
        expect do
          described_class.new(account: new_account, base_contact: base_contact,
                              mergee_contact: mergee_contact).perform
        end.to raise_error('contact does not belong to the account')
      end
    end
  end
end
