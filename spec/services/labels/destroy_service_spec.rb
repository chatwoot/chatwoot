require 'rails_helper'

describe Labels::DestroyService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:label) { create(:label, account: account) }
  let(:contact) { conversation.contact }
  let(:other_conversation) { create(:conversation, account: account) }

  before do
    conversation.label_list.add(label.title)
    conversation.label_list.add('billing')
    conversation.save!

    contact.label_list.add(label.title)
    contact.label_list.add('vip')
    contact.save!
  end

  describe '#perform' do
    it 'removes label from associated conversations and contacts' do
      tagging_ids = existing_label_taggings

      described_class.new(
        label_title: label.title,
        account_id: account.id,
        tagging_ids: tagging_ids
      ).perform

      expect(conversation.reload.label_list).to eq(['billing'])
      expect(contact.reload.label_list).to eq(['vip'])
    end

    it 'does not remove labels added after enqueuing' do
      tagging_ids = existing_label_taggings
      other_conversation.label_list.add(label.title)
      other_conversation.save!

      described_class.new(
        label_title: label.title,
        account_id: account.id,
        tagging_ids: tagging_ids
      ).perform

      expect(other_conversation.reload.label_list).to eq([label.title])
    end
  end

  def existing_label_taggings
    conversation_taggings = ActsAsTaggableOn::Tagging
                            .joins(:tag)
                            .where(context: 'labels', taggable: conversation, tags: { name: label.title })
                            .pluck(:id)

    contact_taggings = ActsAsTaggableOn::Tagging
                       .joins(:tag)
                       .where(context: 'labels', taggable: contact, tags: { name: label.title })
                       .pluck(:id)

    conversation_taggings + contact_taggings
  end
end
