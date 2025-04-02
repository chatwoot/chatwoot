# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportPolicy, type: :policy do
  subject(:report_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:report) { :report }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  # Create a custom role with report_manage permission
  let(:custom_role) { create(:custom_role, account: account, permissions: ['report_manage']) }
  let(:agent_with_role) { create(:user, account: account) }
  let(:agent_with_role_account_user) { create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role) }
  let(:agent_with_role_context) { { user: agent_with_role, account: account, account_user: agent_with_role_account_user } }

  permissions :view? do
    context 'when administrator' do
      it { expect(report_policy).to permit(administrator_context, report) }
    end

    context 'when agent' do
      it { expect(report_policy).not_to permit(agent_context, report) }
    end

    context 'when agent with report_manage permission' do
      it { expect(report_policy).to permit(agent_with_role_context, report) }
    end
  end
end
