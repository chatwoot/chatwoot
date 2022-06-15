# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mention, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'Custom Sort' do
    let!(:account) { create(:account) }
    let!(:user_1) { create(:user, email: 'agent2@example.com', account: account) }
    let!(:conversation_1) { create(:conversation, created_at: DateTime.now - 8.days) }
    let!(:conversation_2) { create(:conversation, created_at: DateTime.now - 6.days) }
    let!(:conversation_3) { create(:conversation, created_at: DateTime.now - 9.days) }

    let!(:mention_1) { create(:mention, account: account, conversation: conversation_1, user: user_1) }
    let!(:mention_2) { create(:mention, account: account, conversation: conversation_2, user: user_1) }
    let!(:mention_3) { create(:mention, account: account, conversation: conversation_3, user: user_1) }

    before do
      create(:message, conversation_id: conversation_1.id, message_type: :incoming, created_at: DateTime.now - 8.days)
      create(:message, conversation_id: conversation_1.id, message_type: :incoming, created_at: DateTime.now - 8.days)
      create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now - 2.days)
      create(:message, conversation_id: conversation_1.id, message_type: :outgoing, created_at: DateTime.now - 7.days)
      create(:message, conversation_id: conversation_2.id, message_type: :incoming, created_at: DateTime.now - 6.days)
      create(:message, conversation_id: conversation_2.id, message_type: :incoming, created_at: DateTime.now - 6.days)
      create(:message, conversation_id: conversation_3.id, message_type: :outgoing, created_at: DateTime.now - 9.days)
      create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now - 6.days)
      create(:message, conversation_id: conversation_3.id, message_type: :incoming, created_at: DateTime.now - 6.days)
    end

    it 'Sort mentioned conversations based on created_at' do
      records = described_class.sort_on_created_at

      expect(records.first.id).to eq(mention_1.id)
      expect(records.first.conversation_id).to eq(conversation_1.id)
      expect(records.last.conversation_id).to eq(conversation_3.id)
    end

    it 'Sort mentioned conversations based on last_user_message_at' do
      records = described_class.last_user_message_at

      expect(records.first.id).to eq(mention_2.id)
      expect(records.first.conversation_id).to eq(conversation_2.id)
      expect(records.last.conversation_id).to eq(conversation_3.id)
    end

    it 'Sort conversations based on mentioned_at' do
      records = described_class.latest

      expect(records.first.id).to eq(mention_3.id)
      expect(records.first.conversation_id).to eq(conversation_3.id)
      expect(records.last.conversation_id).to eq(conversation_1.id)
    end
  end
end
