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

  describe 'sla_policy' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:different_account_sla_policy) { create(:sla_policy) }

    context 'when sla_policy is getting updated' do
      it 'throws error if sla policy belongs to different account' do
        conversation.sla_policy = different_account_sla_policy
        expect(conversation.valid?).to be false
        expect(conversation.errors[:sla_policy]).to include('sla policy account mismatch')
      end

      it 'creates applied sla record if sla policy is present' do
        conversation.sla_policy = sla_policy
        conversation.save!
        expect(conversation.applied_sla.sla_policy_id).to eq(sla_policy.id)
      end

      it 'deletes applied sla record if sla policy is removed' do
        conversation.sla_policy = sla_policy
        conversation.save!
        conversation.sla_policy = nil
        conversation.save!
        conversation.reload
        expect(conversation.applied_sla.present?).to be false
      end
    end
  end
end
