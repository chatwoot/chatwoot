# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise::ReportPolicy', type: :policy do
  subject(:report_policy) { ReportPolicy }

  let(:account) { create(:account) }
  let(:report) { :report }

  # Create a custom role with report_manage permission
  let(:custom_role) { create(:custom_role, account: account, permissions: ['report_manage']) }
  let(:agent_with_role) { create(:user) } # Create without account
  let(:agent_with_role_account_user) do
    create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
  end
  let(:agent_with_role_context) do
    { user: agent_with_role, account: account, account_user: agent_with_role_account_user }
  end

  permissions :view? do
    context 'when agent with report_manage permission' do
      it { expect(report_policy).to permit(agent_with_role_context, report) }
    end
  end
end
