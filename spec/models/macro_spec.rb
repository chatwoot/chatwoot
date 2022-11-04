require 'rails_helper'

RSpec.describe Macro, type: :model do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    it 'validation action name' do
      macro = FactoryBot.build(:macro, account: account, created_by: admin, updated_by: admin, actions: [{ action_name: :update_last_seen }])
      expect(macro).not_to be_valid
      expect(macro.errors.full_messages).to eq(['Actions Macro execution actions update_last_seen not supported.'])
    end
  end

  describe '#set_visibility' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:macro) { create(:macro, account: account, created_by: admin, updated_by: admin, actions: []) }

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
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :global, actions: [])
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :global, actions: [])
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :personal, actions: [])
      create(:macro, account: account, created_by: admin, updated_by: admin, visibility: :personal, actions: [])
      create(:macro, account: account, created_by: agent_1, updated_by: agent_1, visibility: :personal, actions: [])
      create(:macro, account: account, created_by: agent_1, updated_by: agent_1, visibility: :personal, actions: [])
      create(:macro, account: account, created_by: agent_2, updated_by: agent_2, visibility: :personal, actions: [])
      create(:macro, account: account, created_by: agent_2, updated_by: agent_2, visibility: :personal, actions: [])
      create(:macro, account: account, created_by: agent_2, updated_by: agent_2, visibility: :personal, actions: [])
    end

    context 'when user is administrator' do
      it 'return all macros in account' do
        Current.user = admin
        Current.account = account

        macros = account.macros.global.or(account.macros.personal.where(created_by_id: admin.id))

        expect(described_class.with_visibility(admin, {}).count).to eq(macros.count)
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

  describe '#associations' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let!(:global_macro) { FactoryBot.create(:macro, account: account, created_by: agent, updated_by: agent, visibility: :global, actions: []) }
    let!(:personal_macro) { FactoryBot.create(:macro, account: account, created_by: agent, updated_by: agent, visibility: :personal, actions: []) }

    context 'when you delete the author' do
      it 'nullify the created_by column' do
        expect(global_macro.created_by).to eq(agent)
        expect(global_macro.updated_by).to eq(agent)
        expect(personal_macro.created_by).to eq(agent)
        expect(personal_macro.updated_by).to eq(agent)

        personal_macro_id = personal_macro.id
        agent.destroy!

        expect(global_macro.reload.created_by).to be_nil
        expect(global_macro.reload.updated_by).to be_nil
        expect(described_class.find_by(id: personal_macro_id)).to be_nil
      end
    end
  end
end
