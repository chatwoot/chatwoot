require 'rails_helper'

RSpec.describe Conversations::ReadStateService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:seller) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, read_baseline_at: 1.hour.ago) }
  let(:service) { described_class.new(conversation: conversation, user: admin) }

  before do
    account.enable_features!(:individual_conversation_reads, :conversation_unread_counts)
    account.disable_features!(:unread_count_for_filters)
    create(:inbox_member, user: seller, inbox: inbox)
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming, created_at: 1.minute.ago)
  end

  it 'broadcasts read changes to the reader only, including their other sessions' do
    expect(ActionCableBroadcastJob).to receive(:perform_later).with(
      [admin.pubsub_token], 'conversation.read_state_changed', hash_including(id: conversation.display_id, unread_count: 0)
    )
    expect(ActionCableBroadcastJob).to receive(:perform_later).with(
      [admin.pubsub_token], 'conversation.unread_count_changed', { account_id: account.id }
    )
    service.mark_read
  end

  it 'does not create duplicate receipts when a reader opens the conversation repeatedly' do
    service.mark_read
    described_class.new(conversation: conversation.reload, user: admin).mark_read
    expect(conversation.conversation_read_states.where(user: admin).count).to eq(1)
  end

  it 'counts a new customer message independently for both readers' do
    service.mark_read
    described_class.new(conversation: conversation, user: seller).mark_read
    travel_to 1.minute.from_now do
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
      expect(described_class.new(conversation: conversation, user: admin).payload[:unread_count]).to eq(1)
      expect(described_class.new(conversation: conversation, user: seller).payload[:unread_count]).to eq(1)
    end
  end

  it 'advances the personal timeline marker when reading a new internal note' do
    service.mark_read
    travel_to 1.minute.from_now do
      note = create(:message, conversation: conversation, account: account, inbox: inbox, sender: admin, message_type: :outgoing, private: true)
      service.mark_read
      expect(service.last_seen_at).to be >= note.created_at
      expect(service.payload[:unread_count]).to eq(0)
    end
  end

  it 'uses the personal marker when ordering by unread messages' do
    other = create(:conversation, account: account, inbox: inbox, read_baseline_at: 1.hour.ago)
    create_list(:message, 2, conversation: other, account: account, inbox: inbox, message_type: :incoming, created_at: 1.minute.ago)
    described_class.new(conversation: other, user: admin).mark_read
    Current.account = account
    Current.user = admin
    expect(account.conversations.sort_on_unread('desc').first).to eq(conversation)
    Current.user = seller
    expect(account.conversations.sort_on_unread('desc').first).to eq(other)
  ensure
    Current.reset
  end

  it 'does not change another reader when manually marking an empty conversation unread' do
    empty = create(:conversation, account: account, inbox: inbox, read_baseline_at: 1.hour.ago)
    described_class.new(conversation: empty, user: admin).mark_unread
    expect(described_class.new(conversation: empty, user: admin).payload[:unread_count]).to eq(0)
    expect(empty.read_state_for(seller).last_seen_at).to eq(empty.read_baseline_at)
  end
end
