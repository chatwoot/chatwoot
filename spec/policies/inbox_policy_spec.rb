# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxPolicy, type: :policy do
  subject(:inbox_policy) { described_class }

  let(:account) { create(:account) }

  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:inbox) { create(:inbox) }
  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  permissions :create?, :destroy?, :update?, :set_agent_bot? do
    context 'when administrator' do
      it { expect(inbox_policy).to permit(administrator_context, inbox) }
    end

    context 'when agent' do
      it { expect(inbox_policy).not_to permit(agent_context, inbox) }
    end
  end

  permissions :index? do
    context 'when administrator' do
      it { expect(inbox_policy).to permit(administrator_context, inbox) }
    end

    context 'when agent' do
      it { expect(inbox_policy).to permit(agent_context, inbox) }
    end
  end
end
