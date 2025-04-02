require 'rails_helper'

RSpec.describe CategoryPolicy, type: :policy do
  subject(:category_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:portal) { create(:portal, account: account) }
  let(:category) { create(:category, account: account, portal: portal, slug: 'test-category') }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  # Create a custom role with knowledge_base_manage permission
  let(:custom_role) { create(:custom_role, account: account, permissions: ['knowledge_base_manage']) }
  let(:agent_with_role) { create(:user) } # Create without account to avoid duplicate user in account
  let(:agent_with_role_account_user) do
    create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
  end
  let(:agent_with_role_context) do
    { user: agent_with_role, account: account, account_user: agent_with_role_account_user }
  end

  permissions :update?, :show?, :edit?, :create?, :destroy? do
    context 'when administrator' do
      it { expect(category_policy).to permit(administrator_context, category) }
    end

    context 'when agent' do
      it { expect(category_policy).not_to permit(agent_context, category) }
    end

    context 'when agent with knowledge_base_manage permission' do
      it { expect(category_policy).to permit(agent_with_role_context, category) }
    end
  end
end
