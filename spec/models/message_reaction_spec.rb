# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageReaction do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:sender).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:direction) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:direction).with_values(incoming: 0, outgoing: 1) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, removed: 1) }
  end

  describe '#push_event_data' do
    let(:reaction) { create(:message_reaction, emoji: '👍', reaction_type: 'emoji') }

    it 'returns websocket-safe reaction data' do
      expect(reaction.push_event_data).to include(
        id: reaction.id,
        message_id: reaction.message_id,
        conversation_id: reaction.conversation_id,
        emoji: '👍',
        reaction_type: 'emoji',
        direction: 'incoming',
        status: 'active'
      )
    end
  end
end
