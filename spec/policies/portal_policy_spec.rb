# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PortalPolicy, type: :policy do
  subject(:portal_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:portal) { create(:portal, account: account) }

  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  permissions :index?, :show? do
    context 'when administrator' do
      it { expect(portal_policy).to permit(administrator_context, portal) }
    end

    context 'when agent' do
      it { expect(portal_policy).to permit(agent_context, portal) }
    end
  end

  permissions :update?, :edit?, :create?, :destroy?, :logo? do
    context 'when administrator' do
      it { expect(portal_policy).to permit(administrator_context, portal) }
    end

    context 'when agent' do
      it { expect(portal_policy).not_to permit(agent_context, portal) }
    end
  end
end
