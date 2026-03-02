# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Saas::AiAgentInboxPolicy, type: :policy do
  subject { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:ai_agent) { create(:ai_agent, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:ai_agent_inbox) { create(:ai_agent_inbox, ai_agent: ai_agent, inbox: inbox) }

  let(:admin_context) { { user: administrator, account: account, account_user: administrator.account_users.find_by(account: account) } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.find_by(account: account) } }

  permissions :create?, :update?, :destroy? do
    context 'when administrator' do
      it { expect(subject).to permit(admin_context, ai_agent_inbox) }
    end

    context 'when agent' do
      it { expect(subject).not_to permit(agent_context, ai_agent_inbox) }
    end
  end
end
