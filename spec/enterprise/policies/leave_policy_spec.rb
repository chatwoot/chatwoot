require 'rails_helper'

RSpec.describe LeavePolicy, type: :policy do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }

  let(:admin_context) { { user: administrator, account: account, account_user: administrator.account_users.find_by(account: account) } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.find_by(account: account) } }
  let(:other_agent_context) { { user: other_agent, account: account, account_user: other_agent.account_users.find_by(account: account) } }

  describe 'update?' do
    let(:agent_leave) { create(:leave, account: account, user: agent, status: :pending) }

    context 'when leave is pending' do
      context 'when user is administrator' do
        it 'allows update of any leave' do
          policy = described_class.new(admin_context, agent_leave)
          expect(policy.update?).to be true
        end
      end

      context 'when user owns the leave' do
        it 'allows update' do
          policy = described_class.new(agent_context, agent_leave)
          expect(policy.update?).to be true
        end
      end

      context 'when user does not own the leave' do
        it 'denies update' do
          policy = described_class.new(other_agent_context, agent_leave)
          expect(policy.update?).to be false
        end
      end
    end

    context 'when leave is not pending' do
      context 'when user is administrator' do
        it 'denies update of approved leave' do
          approved_leave = create(:leave, account: account, user: agent, status: :approved)
          policy = described_class.new(admin_context, approved_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of rejected leave' do
          rejected_leave = create(:leave, account: account, user: agent, status: :rejected)
          policy = described_class.new(admin_context, rejected_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of cancelled leave' do
          cancelled_leave = create(:leave, account: account, user: agent, status: :cancelled)
          policy = described_class.new(admin_context, cancelled_leave)
          expect(policy.update?).to be false
        end
      end

      context 'when user owns the leave' do
        it 'denies update of approved leave' do
          approved_leave = create(:leave, account: account, user: agent, status: :approved)
          policy = described_class.new(agent_context, approved_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of rejected leave' do
          rejected_leave = create(:leave, account: account, user: agent, status: :rejected)
          policy = described_class.new(agent_context, rejected_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of cancelled leave' do
          cancelled_leave = create(:leave, account: account, user: agent, status: :cancelled)
          policy = described_class.new(agent_context, cancelled_leave)
          expect(policy.update?).to be false
        end
      end
    end
  end

  describe 'destroy?' do
    context 'when leave can be cancelled' do
      context 'when user is administrator' do
        it 'allows destroy of pending leave' do
          pending_leave = create(:leave, account: account, user: agent, status: :pending)
          policy = described_class.new(admin_context, pending_leave)
          expect(policy.destroy?).to be true
        end

        it 'allows destroy of approved future leave' do
          approved_future_leave = create(:leave, account: account, user: agent, status: :approved,
                                                 start_date: 1.week.from_now.to_date,
                                                 end_date: 2.weeks.from_now.to_date)
          policy = described_class.new(admin_context, approved_future_leave)
          expect(policy.destroy?).to be true
        end

        it 'allows destroy of other user leaves' do
          other_leave = create(:leave, account: account, user: other_agent, status: :pending)
          policy = described_class.new(admin_context, other_leave)
          expect(policy.destroy?).to be true
        end
      end

      context 'when user owns the leave' do
        it 'allows destroy of own pending leave' do
          pending_leave = create(:leave, account: account, user: agent, status: :pending)
          policy = described_class.new(agent_context, pending_leave)
          expect(policy.destroy?).to be true
        end

        it 'allows destroy of own approved future leave' do
          approved_future_leave = create(:leave, account: account, user: agent, status: :approved,
                                                 start_date: 1.week.from_now.to_date,
                                                 end_date: 2.weeks.from_now.to_date)
          policy = described_class.new(agent_context, approved_future_leave)
          expect(policy.destroy?).to be true
        end
      end

      context 'when user does not own the leave' do
        it 'denies destroy of other user leave' do
          pending_leave = create(:leave, account: account, user: agent, status: :pending)
          policy = described_class.new(other_agent_context, pending_leave)
          expect(policy.destroy?).to be false
        end
      end
    end

    context 'when leave cannot be cancelled' do
      context 'when user is administrator' do
        it 'denies destroy of current approved leave' do
          approved_current_leave = create(:leave, account: account, user: agent, status: :approved,
                                                  start_date: Date.current, end_date: Date.current + 2.days)
          policy = described_class.new(admin_context, approved_current_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of past approved leave' do
          approved_past_leave = create(:leave, account: account, user: agent, status: :approved,
                                               start_date: 1.week.ago.to_date, end_date: 3.days.ago.to_date)
          policy = described_class.new(admin_context, approved_past_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of rejected leave' do
          rejected_leave = create(:leave, account: account, user: agent, status: :rejected)
          policy = described_class.new(admin_context, rejected_leave)
          expect(policy.destroy?).to be false
        end
      end

      context 'when user owns the leave' do
        it 'denies destroy of current approved leave' do
          approved_current_leave = create(:leave, account: account, user: agent, status: :approved,
                                                  start_date: Date.current, end_date: Date.current + 2.days)
          policy = described_class.new(agent_context, approved_current_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of past approved leave' do
          approved_past_leave = create(:leave, account: account, user: agent, status: :approved,
                                               start_date: 1.week.ago.to_date, end_date: 3.days.ago.to_date)
          policy = described_class.new(agent_context, approved_past_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of rejected leave' do
          rejected_leave = create(:leave, account: account, user: agent, status: :rejected)
          policy = described_class.new(agent_context, rejected_leave)
          expect(policy.destroy?).to be false
        end
      end
    end
  end

  describe 'Scope' do
    before do
      create(:leave, account: account, user: administrator)
      create(:leave, account: account, user: agent)
      create(:leave, account: account, user: other_agent)
    end

    context 'when user is administrator' do
      it 'returns all leaves in account with includes' do
        scope = LeavePolicy::Scope.new(admin_context, Leave.all)
        result = scope.resolve

        expect(result.count).to eq(3)
        expect(result.includes_values).to include(:user, :approver)
        expect(result.map(&:user_id)).to contain_exactly(administrator.id, agent.id, other_agent.id)
      end
    end

    context 'when user is not administrator' do
      it 'returns only own leaves with includes' do
        scope = LeavePolicy::Scope.new(agent_context, Leave.all)
        result = scope.resolve

        expect(result.count).to eq(1)
        expect(result.first.user_id).to eq(agent.id)
        expect(result.includes_values).to include(:user, :approver)
      end

      it 'filters correctly for other agent' do
        scope = LeavePolicy::Scope.new(other_agent_context, Leave.all)
        result = scope.resolve

        expect(result.count).to eq(1)
        expect(result.first.user_id).to eq(other_agent.id)
      end
    end

    context 'when initializing scope' do
      it 'properly initializes all context variables' do
        scope = LeavePolicy::Scope.new(admin_context, Leave.all)

        expect(scope.user_context).to eq(admin_context)
        expect(scope.user).to eq(administrator)
        expect(scope.account).to eq(account)
        expect(scope.account_user).to eq(administrator.account_users.find_by(account: account))
        expect(scope.scope).to eq(Leave.all)
      end
    end
  end

  describe 'ownership checks' do
    describe '#owned_by_user?' do
      it 'returns true when user owns the leave' do
        agent_leave = create(:leave, account: account, user: agent, status: :pending)
        policy = described_class.new(agent_context, agent_leave)
        expect(policy.send(:owned_by_user?)).to be true
      end

      it 'returns false when user does not own the leave' do
        agent_leave = create(:leave, account: account, user: agent, status: :pending)
        policy = described_class.new(other_agent_context, agent_leave)
        expect(policy.send(:owned_by_user?)).to be false
      end

      it 'returns false when record is nil' do
        policy = described_class.new(agent_context, nil)
        expect(policy.send(:owned_by_user?)).to be false
      end
    end
  end
end
