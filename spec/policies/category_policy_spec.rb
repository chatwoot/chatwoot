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

  permissions :index? do
    context 'when administrator' do
      it { expect(category_policy).to permit(administrator_context, category) }
    end

    context 'when agent' do
      it { expect(category_policy).to permit(agent_context, category) }
    end
  end

  permissions :update?, :show?, :edit?, :create?, :destroy? do
    context 'when administrator' do
      it { expect(category_policy).to permit(administrator_context, category) }
    end

    context 'when agent' do
      it { expect(category_policy).not_to permit(agent_context, category) }
    end
  end
end
