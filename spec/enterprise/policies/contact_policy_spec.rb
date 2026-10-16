# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise::ContactPolicy', type: :policy do
  subject(:contact_policy) { ContactPolicy }

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:custom_role) { create(:custom_role, account: account, permissions: ['contact_manage']) }
  let(:agent) { create(:user) }
  let(:account_user) { create(:account_user, user: agent, account: account, role: :agent, custom_role: custom_role) }
  let(:agent_context) { { user: agent, account: account, account_user: account_user } }

  permissions :export? do
    context 'when agent has contact_manage permission' do
      it { expect(contact_policy).to permit(agent_context, contact) }
    end
  end

  permissions :import? do
    context 'when agent has contact_manage permission' do
      it { expect(contact_policy).to permit(agent_context, contact) }
    end
  end
end
