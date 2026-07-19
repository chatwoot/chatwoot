require 'rails_helper'

RSpec.describe Conversations::InheritContactLabelsService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end

  before do
    account.labels.find_or_create_by!(title: 'cliente') { |label| label.color = '#1f93ff' }
    account.labels.find_or_create_by!(title: 'promo001_01') { |label| label.color = '#1f93ff' }
    account.labels.find_or_create_by!(title: 'quejas') { |label| label.color = '#1f93ff' }
  end

  describe '#perform' do
    it 'adds missing contact labels to the conversation' do
      contact.update!(label_list: %w[cliente promo001_01])

      described_class.new(conversation: conversation).perform

      expect(conversation.reload.label_list.map(&:downcase)).to include('cliente', 'promo001_01')
    end

    it 'keeps conversation-only labels while inheriting new contact labels' do
      contact.update!(label_list: %w[cliente])
      described_class.new(conversation: conversation).perform
      conversation.update!(label_list: conversation.label_list.map(&:to_s) + ['quejas'])

      contact.update!(label_list: %w[cliente promo001_01])
      described_class.new(conversation: conversation.reload).perform

      labels = conversation.reload.label_list.map(&:downcase)
      expect(labels).to include('cliente', 'promo001_01', 'quejas')
    end

    it 'does not remove conversation labels when contact labels are cleared' do
      contact.update!(label_list: %w[promo001_01])
      described_class.new(conversation: conversation).perform
      expect(conversation.reload.label_list.map(&:downcase)).to include('promo001_01')

      contact.update!(label_list: [])
      described_class.new(conversation: conversation.reload).perform

      expect(conversation.reload.label_list.map(&:downcase)).to include('promo001_01')
    end

    it 'is a no-op when contact has no labels' do
      expect { described_class.new(conversation: conversation).perform }
        .not_to(change { conversation.reload.label_list.to_a })
    end
  end

  describe 'hooks' do
    it 'registers create callback on Conversation' do
      filter = Conversation._commit_callbacks.select { |cb| cb.kind == :after && cb.name == :inherit_contact_labels }
      expect(filter).to be_present
    end

    it 'inherits contact labels when an incoming message is created' do
      contact.update!(label_list: %w[promo001_01])
      conversation

      message = build(:message, account: account, inbox: inbox, conversation: conversation,
                                message_type: :incoming, sender: contact)
      message.run_callbacks(:commit) { message.send(:inherit_contact_labels_on_incoming) }

      expect(conversation.reload.label_list.map(&:downcase)).to include('promo001_01')
    end
  end
end
