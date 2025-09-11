# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageTemplatePolicy, type: :policy do
  subject(:message_template_policy) { described_class }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:message_template) { create(:message_template, account: account, inbox: inbox) }

  let(:administrator) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }

  let(:administrator_context) { { user: administrator, account: account, account_user: administrator.account_users.first } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.first } }

  permissions :create?, :update?, :destroy? do
    context 'when administrator' do
      it { expect(message_template_policy).to permit(administrator_context, message_template) }
    end

    context 'when agent' do
      it { expect(message_template_policy).not_to permit(agent_context, message_template) }
    end
  end

  permissions :index?, :show? do
    context 'when administrator' do
      it { expect(message_template_policy).to permit(administrator_context, message_template) }
    end

    context 'when agent' do
      it { expect(message_template_policy).to permit(agent_context, message_template) }
    end
  end
end
