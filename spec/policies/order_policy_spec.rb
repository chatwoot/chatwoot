require 'rails_helper'

RSpec.describe OrderPolicy, type: :policy do
  subject { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator_context) { { user: administrator, account: account, account_user: administrator.account_users.find_by(account: account) } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.find_by(account: account) } }

  permissions :create? do
    it 'allows administrators' do
      expect(subject).to permit(administrator_context, Order)
    end

    it 'allows agents' do
      expect(subject).to permit(agent_context, Order)
    end
  end

  permissions :index? do
    it 'allows administrators' do
      expect(subject).to permit(administrator_context, Order)
    end

    it 'allows agents' do
      expect(subject).to permit(agent_context, Order)
    end
  end

  permissions :search? do
    it 'allows administrators' do
      expect(subject).to permit(administrator_context, Order)
    end

    it 'allows agents' do
      expect(subject).to permit(agent_context, Order)
    end
  end
end
