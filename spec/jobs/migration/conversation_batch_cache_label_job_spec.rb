require 'rails_helper'

RSpec.describe Migration::ConversationBatchCacheLabelJob do
  let(:conversation) { create(:conversation, label_list: ['runner']).reload }

  [nil, ''].each do |cached_labels|
    it "rebuilds a #{cached_labels.inspect} cache from existing taggings" do
      conversation.update!(cached_label_list: cached_labels)

      expect { described_class.perform_now([conversation]) }
        .not_to(change { conversation.label_taggings.count })

      expect(conversation.reload.cached_label_list).to eq('runner')
      expect(conversation.labels.pluck(:name)).to eq(['runner'])
    end
  end

  it 'includes labels added after the batch instance loaded its label list' do
    expect(conversation.label_list).to eq(['runner'])
    Conversation.find(conversation.id).add_labels(['lead'])

    described_class.perform_now([conversation])

    expect(conversation.reload.cached_label_list_array).to contain_exactly('runner', 'lead')
    expect(conversation.labels.pluck(:name)).to contain_exactly('runner', 'lead')
  end

  it 'clears a stale cache when the conversation has no taggings' do
    conversation.update_labels([])
    conversation.update!(cached_label_list: 'runner')

    described_class.perform_now([conversation])

    expect(conversation.reload.cached_label_list).to eq('')
    expect(conversation.labels).to be_empty
  end
end
