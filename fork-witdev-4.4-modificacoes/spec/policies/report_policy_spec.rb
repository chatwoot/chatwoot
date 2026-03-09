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

  permissions :view? do
    context 'when administrator' do
      it { expect(report_policy).to permit(administrator_context, report) }
    end

    context 'when agent' do
      it { expect(report_policy).not_to permit(agent_context, report) }
    end
  end
end
