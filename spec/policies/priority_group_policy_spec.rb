# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriorityGroupPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:account) { create(:account) }

  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  let(:priority_group) { create(:priority_group, account: account) }

  permissions :index? do
    context 'when administrator' do
      it { expect(policy).to permit(administrator_context, priority_group) }
    end

    context 'when agent' do
      it { expect(policy).to permit(agent_context, priority_group) }
    end
  end
end
