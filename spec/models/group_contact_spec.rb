# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupContact do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact) }
  end

  describe 'validations' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, group: true, account: account) }
    let(:contact) { create(:contact, account: account) }

    it 'validates presence of conversation_id' do
      group_contact = described_class.new(contact: contact, account: account)
      expect(group_contact).not_to be_valid
      expect(group_contact.errors[:conversation_id]).to include("can't be blank")
    end

    it 'validates presence of contact_id' do
      group_contact = described_class.new(conversation: conversation, account: account)
      expect(group_contact).not_to be_valid
      expect(group_contact.errors[:contact_id]).to include("can't be blank")
    end

    it 'validates uniqueness of contact_id scoped to conversation_id' do
      create(:group_contact, conversation: conversation, contact: contact, account: account)
      duplicate = build(:group_contact, conversation: conversation, contact: contact, account: account)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:contact_id]).to include('has already been taken')
    end

    it 'validates conversation is a group conversation' do
      non_group_conversation = create(:conversation, group: false, account: account)
      group_contact = build(:group_contact, conversation: non_group_conversation, contact: contact, account: account)
      expect(group_contact).not_to be_valid
      expect(group_contact.errors[:conversation]).to include('must be a group conversation')
    end

    it 'validates contact belongs to same account as conversation' do
      other_account = create(:account)
      other_contact = create(:contact, account: other_account)
      group_contact = build(:group_contact, conversation: conversation, contact: other_contact, account: account)
      expect(group_contact).not_to be_valid
      expect(group_contact.errors[:contact]).to include('must belong to the same account')
    end
  end

  describe 'callbacks' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, group: true, account: account) }
    let(:contact) { create(:contact, account: account) }

    describe '#ensure_account_id' do
      it 'sets account_id from conversation before validation' do
        group_contact = described_class.new(conversation: conversation, contact: contact)
        group_contact.valid?
        expect(group_contact.account_id).to eq(conversation.account_id)
      end
    end

    describe '#dispatch_contact_added_event' do
      it 'dispatches CONVERSATION_CONTACT_ADDED event after create' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        create(:group_contact, conversation: conversation, contact: contact, account: account)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'conversation.contact_added',
          kind_of(Time),
          conversation: conversation,
          contact: contact
        )
      end
    end

    describe '#dispatch_contact_removed_event' do
      it 'dispatches CONVERSATION_CONTACT_REMOVED event after destroy' do
        group_contact = create(:group_contact, conversation: conversation, contact: contact, account: account)
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        group_contact.destroy!
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'conversation.contact_removed',
          kind_of(Time),
          conversation: conversation,
          contact: contact
        )
      end
    end
  end
end
