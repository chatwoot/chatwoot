require 'rails_helper'

describe ActionService do
  let(:account) { create(:account) }

  describe '#add_sla' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:action_service) { described_class.new(conversation) }

    it 'adds the sla policy to the conversation and create applied_sla entry' do
      action_service.add_sla(sla_policy)
      expect(conversation.reload.sla_policy_id).to eq(sla_policy.id)

      # check if appliedsla table entry is created with matching attributes
      applied_sla = AppliedSla.last
      expect(applied_sla.account_id).to eq(account.id)
      expect(applied_sla.sla_policy_id).to eq(sla_policy.id)
      expect(applied_sla.conversation_id).to eq(conversation.id)
      expect(applied_sla.sla_status).to eq('active')
    end
  end
end
