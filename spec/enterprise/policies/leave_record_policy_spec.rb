require 'rails_helper'

RSpec.describe LeaveRecordPolicy, type: :policy do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:leave_record) { create(:leave_record, account: account, user: agent) }

  describe 'permissions' do
    context 'for administrators' do
      let(:policy) { described_class.new(pundit_context(admin), leave_record) }

      it 'permits all actions' do
        expect(policy.index?).to be true
        expect(policy.show?).to be true
        expect(policy.create?).to be true
        expect(policy.update?).to be true
        expect(policy.destroy?).to be true
        expect(policy.approve?).to be true
        expect(policy.reject?).to be true
      end
    end

    context 'for agents' do
      let(:policy) { described_class.new(pundit_context(agent), leave_record) }

      it 'permits basic actions' do
        expect(policy.index?).to be true
        expect(policy.show?).to be true
        expect(policy.create?).to be true
        expect(policy.update?).to be true
        expect(policy.destroy?).to be true
      end

      it 'denies approval actions' do
        expect(policy.approve?).to be false
        expect(policy.reject?).to be false
      end
    end
  end

  describe 'scope' do
    let!(:agent_leave) { create(:leave_record, account: account, user: agent) }
    let!(:other_agent) { create(:user, account: account, role: :agent) }
    let!(:other_leave) { create(:leave_record, account: account, user: other_agent) }

    it 'returns all leaves for administrators' do
      scope = described_class::Scope.new(pundit_context(admin), LeaveRecord).resolve
      expect(scope).to include(agent_leave, other_leave)
      expect(scope.count).to eq(2)
    end

    it 'returns only own leaves for agents' do
      scope = described_class::Scope.new(pundit_context(agent), LeaveRecord).resolve
      expect(scope).to include(agent_leave)
      expect(scope).not_to include(other_leave)
      expect(scope.count).to eq(1)
    end

    it 'includes associations for performance' do
      scope = described_class::Scope.new(pundit_context(admin), LeaveRecord).resolve
      expect(scope.includes_values).to include(:user, :approved_by)
    end
  end

  private

  def pundit_context(user)
    {
      user: user,
      account: account,
      account_user: user.account_users.find_by(account: account)
    }
  end
end