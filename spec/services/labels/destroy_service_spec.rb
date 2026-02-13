require 'rails_helper'

describe Labels::DestroyService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:label) { create(:label, account: account) }
  let(:contact) { conversation.contact }

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
      described_class.new(
        label_title: label.title,
        account_id: account.id
      ).perform

      expect(conversation.reload.label_list).to eq(['billing'])
      expect(contact.reload.label_list).to eq(['vip'])
    end
  end
end
