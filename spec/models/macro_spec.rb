require 'rails_helper'

RSpec.describe Macro, type: :model do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:created_by) }
    it { is_expected.to belong_to(:updated_by) }
  end

  describe '#set_visibility' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:macro) { create(:macro, account: account, created_by: admin, updated_by: admin) }

    context 'when user is administrator' do
      it 'set visibility with params' do
        expect(macro.visibility).to eq('personal')

        macro.set_visibility(admin, { visibility: :global })

        expect(macro.visibility).to eq('global')

        macro.set_visibility(admin, { visibility: :personal })

        expect(macro.visibility).to eq('personal')
      end
    end

    context 'when user is agent' do
      it 'set visibility always to agent' do
        Current.user = agent
        Current.account = account

        expect(macro.visibility).to eq('personal')

        macro.set_visibility(agent, { visibility: :global })

        expect(macro.visibility).to eq('personal')
      end
    end
  end

  describe '#with_visibility' do
    let(:agent_1) { create(:user, account: account, role: :agent) }
    let(:agent_2) { create(:user, account: account, role: :agent) }

    before do
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :global)
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :global)
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :personal)
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :personal)
      create(:macro, account: account, created_by: agent_1, updated_by: agent_1, visibility: :personal)
      create(:macro, account: account, created_by: agent_1, updated_by: agent_1, visibility: :personal)
      create(:macro, account: account, created_by: agent_2, updated_by: agent_2, visibility: :personal)
      create(:macro, account: account, created_by: agent_2, updated_by: agent_2, visibility: :personal)
      create(:macro, account: account, created_by: agent_2, updated_by: agent_2, visibility: :personal)
    end

    context 'when user is administrator' do
      it 'return all macros in account' do
        Current.user = admin
        Current.account = account

        expect(described_class.with_visibility(admin, {}).count).to eq(account.macros.count)
      end
    end

    context 'when user is agent' do
      it 'return all macros in account and created_by user' do
        Current.user = agent_2
        Current.account = account

        macros_for_agent_2 = account.macros.global.count + agent_2.macros.personal.count
        expect(described_class.with_visibility(agent_2, {}).count).to eq(macros_for_agent_2)

        Current.user = agent_1

        macros_for_agent_1 = account.macros.global.count + agent_1.macros.personal.count
        expect(described_class.with_visibility(agent_1, {}).count).to eq(macros_for_agent_1)
      end
    end
  end
end
