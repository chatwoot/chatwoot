require 'rails_helper'

RSpec.describe LeaveRecordPolicy, type: :policy do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  let(:admin_context) { { user: administrator, account: account, account_user: administrator.account_users.find_by(account: account) } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.find_by(account: account) } }

  describe 'index?' do
    it 'allows administrators to list leave records' do
      policy = described_class.new(admin_context, LeaveRecord)
      expect(policy.index?).to be true
    end

    it 'allows agents to list leave records' do
      policy = described_class.new(agent_context, LeaveRecord)
      expect(policy.index?).to be true
    end
  end

  describe 'show?' do
    let(:leave_record) { create(:leave_record, account: account, user: agent) }

    it 'allows administrators to view any leave record' do
      policy = described_class.new(admin_context, leave_record)
      expect(policy.show?).to be true
    end

    it 'allows agents to view leave records' do
      policy = described_class.new(agent_context, leave_record)
      expect(policy.show?).to be true
    end
  end

  describe 'create?' do
    it 'allows administrators to create leave records' do
      policy = described_class.new(admin_context, LeaveRecord)
      expect(policy.create?).to be true
    end

    it 'allows agents to create leave records' do
      policy = described_class.new(agent_context, LeaveRecord)
      expect(policy.create?).to be true
    end
  end

  describe 'update?' do
    let(:leave_record) { create(:leave_record, account: account, user: agent) }

    it 'allows administrators to access update action' do
      policy = described_class.new(admin_context, leave_record)
      expect(policy.update?).to be true
    end

    it 'allows agents to access update action' do
      policy = described_class.new(agent_context, leave_record)
      expect(policy.update?).to be true
    end
  end

  describe 'destroy?' do
    let(:leave_record) { create(:leave_record, account: account, user: agent) }

    it 'allows administrators to access destroy action' do
      policy = described_class.new(admin_context, leave_record)
      expect(policy.destroy?).to be true
    end

    it 'allows agents to access destroy action' do
      policy = described_class.new(agent_context, leave_record)
      expect(policy.destroy?).to be true
    end
  end

  describe 'approve?' do
    let(:leave_record) { create(:leave_record, account: account, user: agent) }

    it 'allows only administrators to approve leave records' do
      policy = described_class.new(admin_context, leave_record)
      expect(policy.approve?).to be true
    end

    it 'denies agents from approving leave records' do
      policy = described_class.new(agent_context, leave_record)
      expect(policy.approve?).to be false
    end
  end

  describe 'reject?' do
    let(:leave_record) { create(:leave_record, account: account, user: agent) }

    it 'allows only administrators to reject leave records' do
      policy = described_class.new(admin_context, leave_record)
      expect(policy.reject?).to be true
    end

    it 'denies agents from rejecting leave records' do
      policy = described_class.new(agent_context, leave_record)
      expect(policy.reject?).to be false
    end
  end

  describe 'Scope' do
    let(:other_agent) { create(:user, account: account, role: :agent) }

    describe '#resolve' do
      before do
        create(:leave_record, account: account, user: administrator)
        create(:leave_record, account: account, user: agent)
        create(:leave_record, account: account, user: other_agent)
      end

      context 'when user is administrator' do
        it 'returns all leave records in the account' do
          scope = LeaveRecordPolicy::Scope.new(admin_context, account.leave_records)
          result = scope.resolve

          expect(result.count).to eq(3)
          expect(result.map(&:user_id)).to contain_exactly(
            administrator.id,
            agent.id,
            other_agent.id
          )
        end

        it 'includes user and approver associations for performance' do
          scope = LeaveRecordPolicy::Scope.new(admin_context, account.leave_records)
          result = scope.resolve

          expect(result.includes_values).to include(:user, :approver)
        end
      end

      context 'when user is agent' do
        it 'returns only the agent\'s own leave records' do
          scope = LeaveRecordPolicy::Scope.new(agent_context, account.leave_records)
          result = scope.resolve

          expect(result.count).to eq(1)
          expect(result.first.user_id).to eq(agent.id)
        end

        it 'does not return other agents\' leave records' do
          scope = LeaveRecordPolicy::Scope.new(agent_context, account.leave_records)
          result = scope.resolve

          user_ids = result.map(&:user_id)
          expect(user_ids).not_to include(other_agent.id)
          expect(user_ids).not_to include(administrator.id)
        end

        it 'includes user and approver associations for performance' do
          scope = LeaveRecordPolicy::Scope.new(agent_context, account.leave_records)
          result = scope.resolve

          expect(result.includes_values).to include(:user, :approver)
        end
      end
    end

    describe 'initialization' do
      it 'properly sets all context attributes' do
        scope = LeaveRecordPolicy::Scope.new(admin_context, account.leave_records)

        expect(scope.user_context).to eq(admin_context)
        expect(scope.user).to eq(administrator)
        expect(scope.account).to eq(account)
        expect(scope.account_user).to eq(administrator.account_users.find_by(account: account))
        expect(scope.scope).to eq(account.leave_records)
      end
    end
  end
end
