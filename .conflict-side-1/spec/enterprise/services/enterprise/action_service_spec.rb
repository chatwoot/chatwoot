require 'rails_helper'

describe ActionService do
  let(:account) { create(:account) }

  describe '#add_sla' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:action_service) { described_class.new(conversation) }

    context 'when sla_policy_id is present' do
      it 'adds the sla policy to the conversation and create applied_sla entry' do
        action_service.add_sla([sla_policy.id])
        expect(conversation.reload.sla_policy_id).to eq(sla_policy.id)

        # check if appliedsla table entry is created with matching attributes
        applied_sla = AppliedSla.last
        expect(applied_sla.account_id).to eq(account.id)
        expect(applied_sla.sla_policy_id).to eq(sla_policy.id)
        expect(applied_sla.conversation_id).to eq(conversation.id)
        expect(applied_sla.sla_status).to eq('active')
      end
    end

    context 'when sla_policy_id is not present' do
      it 'does not add the sla policy to the conversation' do
        action_service.add_sla(nil)
        expect(conversation.reload.sla_policy_id).to be_nil
      end
    end

    context 'when conversation already has a sla policy' do
      it 'does not add the new sla policy to the conversation' do
        existing_sla_policy = sla_policy
        new_sla_policy = create(:sla_policy, account: account)
        conversation.update!(sla_policy_id: existing_sla_policy.id)
        action_service.add_sla([new_sla_policy.id])
        expect(conversation.reload.sla_policy_id).to eq(existing_sla_policy.id)
      end
    end

    context 'when sla_policy is not found' do
      it 'does not add the sla policy to the conversation' do
        action_service.add_sla([sla_policy.id + 1])
        expect(conversation.reload.sla_policy_id).to be_nil
      end
    end
  end
end
