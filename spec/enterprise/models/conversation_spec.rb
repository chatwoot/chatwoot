require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sla_policy).optional }
  end

  describe 'SLA policy updates' do
    let!(:conversation) { create(:conversation) }
    let!(:sla_policy) { create(:sla_policy, account: conversation.account) }

    it 'generates an activity message when the SLA policy is updated' do
      conversation.update!(sla_policy_id: sla_policy.id)

      perform_enqueued_jobs

      activity_message = conversation.messages.where(message_type: 'activity').last

      expect(activity_message).not_to be_nil
      expect(activity_message.message_type).to eq('activity')
      expect(activity_message.content).to include('added SLA policy')
    end

    # TODO: Reenable this when we let the SLA policy be removed from a conversation
    # it 'generates an activity message when the SLA policy is removed' do
    #   conversation.update!(sla_policy_id: sla_policy.id)
    #   conversation.update!(sla_policy_id: nil)

    #   perform_enqueued_jobs

    #   activity_message = conversation.messages.where(message_type: 'activity').last

    #   expect(activity_message).not_to be_nil
    #   expect(activity_message.message_type).to eq('activity')
    #   expect(activity_message.content).to include('removed SLA policy')
    # end
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
    end

    context 'when conversation already has a different sla' do
      before do
        conversation.update(sla_policy: create(:sla_policy, account: account))
      end

      it 'throws error if trying to assing a different sla' do
        conversation.sla_policy = sla_policy
        expect(conversation.valid?).to be false
        expect(conversation.errors[:sla_policy]).to eq(['conversation already has a different sla'])
      end

      it 'throws error if trying to set sla to nil' do
        conversation.sla_policy = nil
        expect(conversation.valid?).to be false
        expect(conversation.errors[:sla_policy]).to eq(['cannot remove sla policy from conversation'])
      end
    end
  end
end
