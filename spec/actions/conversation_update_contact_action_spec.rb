require 'rails_helper'

describe ::ConversationUpdateContactAction do
  subject(:conversation_update_contact) { described_class.new(account: account, conversation: conversation, contact: new_contact).perform }

  let!(:account) { create(:account) }
  let!(:old_contact) do
    create(:contact, identifier: 'base_contact', email: 'old@old.com', phone_number: '', custom_attributes: { val_test: 'old', val_empty_old: '' },
                     account: account)
  end
  let!(:conversation) { create(:conversation, contact: old_contact) }
  let!(:new_contact) do
    create(:contact, identifier: '', email: 'new@new.com', phone_number: '+12212345',
                     custom_attributes: { val_test: 'new', val_new: 'new', val_empty_new: '' }, account: account)
  end

  before do
    2.times.each do
      create(:message, sender: old_contact, conversation: conversation)
    end
  end

  describe '#perform' do
    it 'move conversation to contact new contact' do
      expect(conversation.contact.id).to be old_contact.id
      conversation_update_contact
      expect(conversation.contact.id).to be new_contact.id
    end

    it 'move contact inbox to new contact' do
      expect(conversation.contact_inbox.contact.id).to be old_contact.id
      conversation_update_contact
      expect(conversation.contact_inbox.contact.id).to be new_contact.id
    end

    it 'moves the messages to new contact' do
      expect(conversation.messages.first.sender.id).to be old_contact.id
      conversation_update_contact
      expect(conversation.messages.first.sender.id).to be new_contact.id
    end

    context 'when contacts belong to a different account' do
      it 'throws an exception' do
        new_account = create(:account)
        expect do
          described_class.new(account: new_account, conversation: conversation, contact: new_contact).perform
        end.to raise_error('contact does not belong to the account')
      end
    end
  end
end
