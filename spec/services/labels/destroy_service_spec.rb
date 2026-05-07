require 'rails_helper'

describe Labels::DestroyService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:label) { create(:label, account: account) }
  let(:contact) { conversation.contact }
  let(:label_deleted_at) { Time.zone.parse('2026-05-07 10:00:00 UTC') }

  before do
    conversation.label_list.add(label.title)
    conversation.label_list.add('billing')
    conversation.save!

    contact.label_list.add(label.title)
    contact.label_list.add('vip')
    contact.save!

    set_label_tagging_created_at(conversation, label_deleted_at - 1.minute)
    set_label_tagging_created_at(contact, label_deleted_at - 1.minute)
  end

  describe '#perform' do
    it 'removes label from associated conversations and contacts' do
      described_class.new(
        label_title: label.title,
        account_id: account.id,
        label_deleted_at: label_deleted_at
      ).perform

      expect(conversation.reload.label_list).to eq(['billing'])
      expect(conversation.cached_label_list).to eq('billing')
      expect(contact.reload.label_list).to eq(['vip'])
    end

    it 'removes label associations after the label record is destroyed' do
      label_title = label.title
      label.destroy!

      described_class.new(
        label_title: label_title,
        account_id: account.id,
        label_deleted_at: label_deleted_at
      ).perform

      expect(conversation.reload.label_list).to eq(['billing'])
      expect(conversation.cached_label_list).to eq('billing')
      expect(contact.reload.label_list).to eq(['vip'])
    end

    it 'does not remove labels from other accounts' do
      other_account = create(:account)
      other_conversation = create(:conversation, account: other_account)
      other_conversation.label_list.add(label.title)
      other_conversation.save!
      set_label_tagging_created_at(other_conversation, label_deleted_at - 1.minute)

      described_class.new(
        label_title: label.title,
        account_id: account.id,
        label_deleted_at: label_deleted_at
      ).perform

      expect(other_conversation.reload.label_list).to eq([label.title])
    end

    it 'does not dispatch conversation or contact update events' do
      expect(Rails.configuration.dispatcher).not_to receive(:dispatch)

      described_class.new(
        label_title: label.title,
        account_id: account.id,
        label_deleted_at: label_deleted_at
      ).perform
    end

    it 'does not remove label associations created after the label was deleted' do
      other_conversation = create(:conversation, account: account)
      other_conversation.label_list.add(label.title)
      other_conversation.save!
      set_label_tagging_created_at(other_conversation, label_deleted_at + 1.minute)

      described_class.new(
        label_title: label.title,
        account_id: account.id,
        label_deleted_at: label_deleted_at
      ).perform

      expect(conversation.reload.label_list).to eq(['billing'])
      expect(conversation.cached_label_list).to eq('billing')
      expect(contact.reload.label_list).to eq(['vip'])
      expect(other_conversation.reload.label_list).to eq([label.title])
    end
  end

  def set_label_tagging_created_at(record, created_at)
    ActsAsTaggableOn::Tagging
      .joins(:tag)
      .find_by!(context: 'labels', taggable: record, tags: { name: label.title })
      .update!(created_at: created_at)
  end
end
