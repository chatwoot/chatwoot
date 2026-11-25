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

  describe '#assignee' do
    it 'has no name when the conversation is unassigned' do
      expect(conversation_drop.assignee.name).to be_nil
    end

    it 'returns the current assignee' do
      conversation.update!(assignee: create(:user, account: account, name: 'john doe'))

      expect(conversation_drop.assignee.name).to eq 'John Doe'
    end
  end

  describe '#before' do
    it 'is nil outside an automation rule execution' do
      expect(conversation_drop.before).to be_nil
    end

    context 'when a snapshot of this conversation is current' do
      let(:agent) { create(:user, account: account, name: 'john doe') }

      before do
        conversation.update!(assignee: agent, custom_attributes: { 'fechamento' => 'Em negociação' })
        Current.conversation_snapshot = ConversationSnapshot.new(conversation.reload)
      end

      after { Current.reset }

      it 'reads the conversation as it was when the execution started' do
        conversation.update!(assignee: nil, custom_attributes: {})

        expect(conversation_drop.before.assignee.name).to eq 'John Doe'
        expect(conversation_drop.before.custom_attribute['fechamento']).to eq 'Em negociação'
        expect(conversation_drop.assignee.name).to be_nil
        expect(conversation_drop.custom_attribute).to eq({})
      end

      it 'does not nest: the snapshot has no snapshot of its own' do
        expect(conversation_drop.before.before).to be_nil
      end

      it 'is nil for any other conversation' do
        other_drop = described_class.new(create(:conversation, account: account))

        expect(other_drop.before).to be_nil
      end
    end
  end
end
