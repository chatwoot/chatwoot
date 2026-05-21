require 'rails_helper'

RSpec.describe CompanyPolicy, type: :policy do
  subject(:company_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:company) { create(:company, account: account) }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  permissions :index?, :show?, :create?, :update? do
    context 'when administrator' do
      it { expect(company_policy).to permit(administrator_context, company) }
    end

    context 'when agent' do
      it { expect(company_policy).to permit(agent_context, company) }
    end
  end

  permissions :destroy? do
    context 'when administrator' do
      it { expect(company_policy).to permit(administrator_context, company) }
    end

    context 'when agent' do
      it { expect(company_policy).not_to permit(agent_context, company) }
    end
  end
end
