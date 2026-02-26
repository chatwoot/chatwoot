require 'rails_helper'

RSpec.describe Captain::McpServerPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:account) { create(:account) }
  let(:mcp_server) { create(:captain_mcp_server, account: account) }

  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.find_by(user: administrator) } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.find_by(user: agent) } }

  permissions :index?, :show?, :create?, :update?, :destroy? do
    context 'when administrator' do
      it { expect(policy).to permit(administrator_context, mcp_server) }
    end

    context 'when agent' do
      it { expect(policy).not_to permit(agent_context, mcp_server) }
    end
  end

  permissions :connect?, :disconnect?, :refresh? do
    context 'when administrator' do
      it { expect(policy).to permit(administrator_context, mcp_server) }
    end

    context 'when agent' do
      it { expect(policy).not_to permit(agent_context, mcp_server) }
    end
  end
end
