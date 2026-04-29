# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::AssistantPolicy, type: :policy do
  subject(:assistant_policy) { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:administrator_context) { { user: administrator, account: account, account_user: account.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: account.account_users.first } }

  permissions :index?, :show?, :playground? do
    context 'when administrator' do
      it { expect(assistant_policy).to permit(administrator_context, assistant) }
    end

    context 'when agent' do
      it { expect(assistant_policy).to permit(agent_context, assistant) }
    end
  end

  permissions :tools?, :create?, :update?, :destroy?, :sync? do
    context 'when administrator' do
      it { expect(assistant_policy).to permit(administrator_context, assistant) }
    end

    context 'when agent' do
      it { expect(assistant_policy).not_to permit(agent_context, assistant) }
    end
  end
end
