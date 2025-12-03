# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise::CategoryPolicy', type: :policy do
  subject(:category_policy) { CategoryPolicy }

  let(:account) { create(:account) }
  let(:portal) { create(:portal, account: account) }
  let(:category) { create(:category, account: account, portal: portal, slug: 'test-category') }

  # Create a custom role with knowledge_base_manage permission
  let(:custom_role) { create(:custom_role, account: account, permissions: ['knowledge_base_manage']) }
  let(:agent_with_role) { create(:user) } # Create without account
  let(:agent_with_role_account_user) do
    create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
  end
  let(:agent_with_role_context) do
    { user: agent_with_role, account: account, account_user: agent_with_role_account_user }
  end

  permissions :index?, :update?, :show?, :edit?, :create?, :destroy? do
    context 'when agent with knowledge_base_manage permission' do
      it { expect(category_policy).to permit(agent_with_role_context, category) }
    end
  end
end
