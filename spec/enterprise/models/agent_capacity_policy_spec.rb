require 'rails_helper'

RSpec.describe AgentCapacityPolicy, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe 'destruction' do
    let(:policy) { create(:agent_capacity_policy, account: account) }
    let(:user) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }

    it 'destroys associated inbox capacity limits' do
      create(:inbox_capacity_limit, agent_capacity_policy: policy, inbox: inbox)
      expect { policy.destroy }.to change(InboxCapacityLimit, :count).by(-1)
    end

    it 'nullifies associated account users' do
      account_user = user.account_users.first
      account_user.update!(agent_capacity_policy: policy)

      policy.destroy!
      expect(account_user.reload.agent_capacity_policy).to be_nil
    end
  end
end
