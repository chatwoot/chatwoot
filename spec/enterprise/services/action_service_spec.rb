require 'rails_helper'

describe ActionService do
  let(:account) { create(:account) }

  describe '#add_sla' do
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:action_service) { described_class.new(conversation) }

    it 'adds the sla policy to the conversation' do
      action_service.add_sla(sla_policy)
      expect(conversation.reload.sla_policy).to eq(sla_policy)
    end
  end
end
