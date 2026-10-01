require 'rails_helper'

describe Labels::UpdateService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:label) { create(:label, account: account) }
  let(:contact) { conversation.contact }

  before do
    conversation.update_labels([label.title, 'billing'])
    contact.update_labels([label.title, 'billing'])
  end

  describe '#perform' do
    let(:service) do
      described_class.new(
        new_label_title: 'updated-label-title',
        old_label_title: label.title,
        account_id: account.id
      )
    end

    it 'renames the label on associated conversations and contacts' do
      service.perform

      expect(conversation.reload.labels.pluck(:name)).to contain_exactly('updated-label-title', 'billing')
      expect(conversation.cached_label_list_array).to contain_exactly('updated-label-title', 'billing')
      expect(contact.reload.labels.pluck(:name)).to contain_exactly('updated-label-title', 'billing')
    end

    it 'does not create label activity messages' do
      expect { service.perform }.not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end
  end
end
