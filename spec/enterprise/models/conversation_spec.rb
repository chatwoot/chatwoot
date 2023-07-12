require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sla_policy).optional }
  end

  describe 'conversation sentiments' do
    include ActiveJob::TestHelper

    let(:conversation) { create(:conversation, additional_attributes: { referer: 'https://www.chatwoot.com/' }) }

    before do
      10.times do
        message = create(:message, conversation_id: conversation.id, account_id: conversation.account_id, message_type: 'incoming')
        message.update(sentiment: { 'label': 'positive', score: '0.4' })
      end
    end

    it 'returns opening sentiments' do
      sentiments = conversation.opening_sentiments
      expect(sentiments[:label]).to eq('positive')
    end

    it 'returns closing sentiments if conversation is not resolved' do
      sentiments = conversation.closing_sentiments
      expect(sentiments).to be_nil
    end

    it 'returns closing sentiments if it is resolved' do
      conversation.resolved!

      sentiments = conversation.closing_sentiments
      expect(sentiments[:label]).to eq('positive')
    end
  end
end
