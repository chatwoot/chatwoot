require 'rails_helper'

describe ConversationDrop do
  subject(:conversation_drop) { described_class.new(conversation) }

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#first_reply_created_at' do
    it 'returns empty string when first_reply_created_at is nil' do
      expect(conversation_drop.first_reply_created_at).to eq ''
    end

    it 'returns formatted date for en locale' do
      conversation.update!(first_reply_created_at: Time.zone.parse('2025-03-15 14:30:00'))
      expect(conversation_drop.first_reply_created_at).to eq 'Mar 15, 2025'
    end

    it 'returns formatted date for pt_BR locale' do
      account.update!(locale: 'pt_BR')
      conversation.update!(first_reply_created_at: Time.zone.parse('2025-03-15 14:30:00'))
      expect(conversation_drop.first_reply_created_at).to eq '15/03/2025'
    end
  end

  describe '#first_reply_created_at_time' do
    it 'returns empty string when first_reply_created_at is nil' do
      expect(conversation_drop.first_reply_created_at_time).to eq ''
    end

    it 'returns formatted date with time for en locale' do
      conversation.update!(first_reply_created_at: Time.zone.parse('2025-03-15 14:30:00'))
      expect(conversation_drop.first_reply_created_at_time).to eq 'Mar 15, 2025 14:30'
    end

    it 'returns formatted date with time for pt_BR locale' do
      account.update!(locale: 'pt_BR')
      conversation.update!(first_reply_created_at: Time.zone.parse('2025-03-15 14:30:00'))
      expect(conversation_drop.first_reply_created_at_time).to eq '15/03/2025 14:30'
    end
  end

  describe '#last_activity_at' do
    it 'returns formatted date' do
      conversation.update!(last_activity_at: Time.zone.parse('2025-06-20 09:15:00'))
      expect(conversation_drop.last_activity_at).to eq 'Jun 20, 2025'
    end

    it 'returns formatted date for pt_BR locale' do
      account.update!(locale: 'pt_BR')
      conversation.update!(last_activity_at: Time.zone.parse('2025-06-20 09:15:00'))
      expect(conversation_drop.last_activity_at).to eq '20/06/2025'
    end
  end

  describe '#last_activity_at_time' do
    it 'returns formatted date with time' do
      conversation.update!(last_activity_at: Time.zone.parse('2025-06-20 09:15:00'))
      expect(conversation_drop.last_activity_at_time).to eq 'Jun 20, 2025 09:15'
    end

    it 'returns formatted date with time for pt_BR locale' do
      account.update!(locale: 'pt_BR')
      conversation.update!(last_activity_at: Time.zone.parse('2025-06-20 09:15:00'))
      expect(conversation_drop.last_activity_at_time).to eq '20/06/2025 09:15'
    end
  end
end
