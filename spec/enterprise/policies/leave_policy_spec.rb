require 'rails_helper'

RSpec.describe LeavePolicy, type: :policy do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }

  let(:admin_account_user) { create(:account_user, account: account, user: administrator, role: :administrator) }
  let(:agent_account_user) { create(:account_user, account: account, user: agent, role: :agent) }
  let(:other_agent_account_user) { create(:account_user, account: account, user: other_agent, role: :agent) }

  let(:admin_context) { { user: administrator, account: account, account_user: admin_account_user } }
  let(:agent_context) { { user: agent, account: account, account_user: agent_account_user } }
  let(:other_agent_context) { { user: other_agent, account: account, account_user: other_agent_account_user } }

  let(:agent_leave) { create(:leave, account: account, user: agent, status: :pending) }
  let(:other_agent_leave) { create(:leave, account: account, user: other_agent, status: :pending) }

  describe 'update?' do
    context 'when leave is pending' do
      context 'when user is administrator' do
        it 'allows update of any leave' do
          policy = LeavePolicy.new(admin_context, agent_leave)
          expect(policy.update?).to be true
        end
      end

      context 'when user owns the leave' do
        it 'allows update' do
          policy = LeavePolicy.new(agent_context, agent_leave)
          expect(policy.update?).to be true
        end
      end

      context 'when user does not own the leave' do
        it 'denies update' do
          policy = LeavePolicy.new(other_agent_context, agent_leave)
          expect(policy.update?).to be false
        end
      end
    end

    context 'when leave is not pending' do
      let(:approved_leave) { create(:leave, account: account, user: agent, status: :approved) }
      let(:rejected_leave) { create(:leave, account: account, user: agent, status: :rejected) }
      let(:cancelled_leave) { create(:leave, account: account, user: agent, status: :cancelled) }

      context 'when user is administrator' do
        it 'denies update of approved leave' do
          policy = LeavePolicy.new(admin_context, approved_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of rejected leave' do
          policy = LeavePolicy.new(admin_context, rejected_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of cancelled leave' do
          policy = LeavePolicy.new(admin_context, cancelled_leave)
          expect(policy.update?).to be false
        end
      end

      context 'when user owns the leave' do
        it 'denies update of approved leave' do
          policy = LeavePolicy.new(agent_context, approved_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of rejected leave' do
          policy = LeavePolicy.new(agent_context, rejected_leave)
          expect(policy.update?).to be false
        end

        it 'denies update of cancelled leave' do
          policy = LeavePolicy.new(agent_context, cancelled_leave)
          expect(policy.update?).to be false
        end
      end
    end
  end

  describe 'destroy?' do
    context 'when leave can be cancelled' do
      let(:pending_leave) { create(:leave, account: account, user: agent, status: :pending) }
      let(:approved_future_leave) do
        create(:leave, account: account, user: agent, status: :approved,
                       start_date: 1.week.from_now.to_date, end_date: 2.weeks.from_now.to_date)
      end

      context 'when user is administrator' do
        it 'allows destroy of pending leave' do
          policy = LeavePolicy.new(admin_context, pending_leave)
          expect(policy.destroy?).to be true
        end

        it 'allows destroy of approved future leave' do
          policy = LeavePolicy.new(admin_context, approved_future_leave)
          expect(policy.destroy?).to be true
        end

        it 'allows destroy of other user leaves' do
          other_leave = create(:leave, account: account, user: other_agent, status: :pending)
          policy = LeavePolicy.new(admin_context, other_leave)
          expect(policy.destroy?).to be true
        end
      end

      context 'when user owns the leave' do
        it 'allows destroy of own pending leave' do
          policy = LeavePolicy.new(agent_context, pending_leave)
          expect(policy.destroy?).to be true
        end

        it 'allows destroy of own approved future leave' do
          policy = LeavePolicy.new(agent_context, approved_future_leave)
          expect(policy.destroy?).to be true
        end
      end

      context 'when user does not own the leave' do
        it 'denies destroy of other user leave' do
          policy = LeavePolicy.new(other_agent_context, pending_leave)
          expect(policy.destroy?).to be false
        end
      end
    end

    context 'when leave cannot be cancelled' do
      let(:approved_current_leave) do
        create(:leave, account: account, user: agent, status: :approved,
                       start_date: Date.current, end_date: Date.current + 2.days)
      end
      let(:approved_past_leave) do
        create(:leave, account: account, user: agent, status: :approved,
                       start_date: 1.week.ago.to_date, end_date: 3.days.ago.to_date)
      end
      let(:rejected_leave) { create(:leave, account: account, user: agent, status: :rejected) }

      context 'when user is administrator' do
        it 'denies destroy of current approved leave' do
          policy = LeavePolicy.new(admin_context, approved_current_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of past approved leave' do
          policy = LeavePolicy.new(admin_context, approved_past_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of rejected leave' do
          policy = LeavePolicy.new(admin_context, rejected_leave)
          expect(policy.destroy?).to be false
        end
      end

      context 'when user owns the leave' do
        it 'denies destroy of current approved leave' do
          policy = LeavePolicy.new(agent_context, approved_current_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of past approved leave' do
          policy = LeavePolicy.new(agent_context, approved_past_leave)
          expect(policy.destroy?).to be false
        end

        it 'denies destroy of rejected leave' do
          policy = LeavePolicy.new(agent_context, rejected_leave)
          expect(policy.destroy?).to be false
        end
      end
    end
  end

  describe 'Scope' do
    let(:admin_leave) { create(:leave, account: account, user: administrator) }
    let(:agent_leave) { create(:leave, account: account, user: agent) }
    let(:other_agent_leave) { create(:leave, account: account, user: other_agent) }

    before do
      admin_leave
      agent_leave
      other_agent_leave
    end

    context 'when user is administrator' do
      it 'returns all leaves in account with includes' do
        scope = LeavePolicy::Scope.new(admin_context, Leave.all)
        result = scope.resolve

        expect(result).to include(admin_leave, agent_leave, other_agent_leave)
        expect(result.includes_values).to include(:user, :approver)
      end
    end

    context 'when user is not administrator' do
      it 'returns only own leaves with includes' do
        scope = LeavePolicy::Scope.new(agent_context, Leave.all)
        result = scope.resolve

        expect(result).to include(agent_leave)
        expect(result).not_to include(admin_leave, other_agent_leave)
        expect(result.includes_values).to include(:user, :approver)
      end

      it 'filters correctly for other agent' do
        scope = LeavePolicy::Scope.new(other_agent_context, Leave.all)
        result = scope.resolve

        expect(result).to include(other_agent_leave)
        expect(result).not_to include(admin_leave, agent_leave)
      end
    end

    context 'scope initialization' do
      it 'properly initializes all context variables' do
        scope = LeavePolicy::Scope.new(admin_context, Leave.all)

        expect(scope.user_context).to eq(admin_context)
        expect(scope.user).to eq(administrator)
        expect(scope.account).to eq(account)
        expect(scope.account_user).to eq(admin_account_user)
        expect(scope.scope).to eq(Leave.all)
      end
    end
  end

  describe 'ownership checks' do
    let(:policy) { LeavePolicy.new(agent_context, agent_leave) }

    describe '#owned_by_user?' do
      it 'returns true when user owns the leave' do
        expect(policy.send(:owned_by_user?)).to be true
      end

      it 'returns false when user does not own the leave' do
        policy = LeavePolicy.new(other_agent_context, agent_leave)
        expect(policy.send(:owned_by_user?)).to be false
      end

      it 'returns false when record is nil' do
        policy = LeavePolicy.new(agent_context, nil)
        expect(policy.send(:owned_by_user?)).to be false
      end
    end
  end
end
