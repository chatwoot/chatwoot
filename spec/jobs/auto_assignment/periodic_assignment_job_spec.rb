require 'rails_helper'

RSpec.describe AutoAssignment::PeriodicAssignmentJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }
  let(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  describe '#perform' do
    context 'when account has assignment_v2 feature enabled' do
      before do
        allow(account).to receive(:feature_enabled?).with('assignment_v2').and_return(true)
        allow(Account).to receive(:find_in_batches).and_yield([account])
      end

      context 'when inbox has auto_assignment_v2 enabled' do
        before do
          allow(inbox).to receive(:auto_assignment_v2_enabled?).and_return(true)
          inbox_relation = instance_double(ActiveRecord::Relation)
          allow(account).to receive(:inboxes).and_return(inbox_relation)
          allow(inbox_relation).to receive(:joins).with(:assignment_policy).and_return(inbox_relation)
          allow(inbox_relation).to receive(:find_in_batches).and_yield([inbox])
        end

        it 'queues assignment job for eligible inboxes' do
          inbox_assignment_policy # ensure it exists
          expect(AutoAssignment::AssignmentJob).to receive(:perform_later).with(inbox_id: inbox.id)

          described_class.new.perform
        end

        it 'processes multiple accounts' do
          inbox_assignment_policy # ensure it exists
          account2 = create(:account)
          inbox2 = create(:inbox, account: account2, enable_auto_assignment: true)
          policy2 = create(:assignment_policy, account: account2)
          create(:inbox_assignment_policy, inbox: inbox2, assignment_policy: policy2)

          allow(account2).to receive(:feature_enabled?).with('assignment_v2').and_return(true)
          allow(inbox2).to receive(:auto_assignment_v2_enabled?).and_return(true)

          inbox_relation2 = instance_double(ActiveRecord::Relation)
          allow(account2).to receive(:inboxes).and_return(inbox_relation2)
          allow(inbox_relation2).to receive(:joins).with(:assignment_policy).and_return(inbox_relation2)
          allow(inbox_relation2).to receive(:find_in_batches).and_yield([inbox2])

          allow(Account).to receive(:find_in_batches).and_yield([account]).and_yield([account2])

          expect(AutoAssignment::AssignmentJob).to receive(:perform_later).with(inbox_id: inbox.id)
          expect(AutoAssignment::AssignmentJob).to receive(:perform_later).with(inbox_id: inbox2.id)

          described_class.new.perform
        end
      end

      context 'when inbox does not have auto_assignment_v2 enabled' do
        before do
          allow(inbox).to receive(:auto_assignment_v2_enabled?).and_return(false)
        end

        it 'does not queue assignment job' do
          expect(AutoAssignment::AssignmentJob).not_to receive(:perform_later)

          described_class.new.perform
        end
      end
    end

    context 'when account does not have assignment_v2 feature enabled' do
      before do
        allow(account).to receive(:feature_enabled?).with('assignment_v2').and_return(false)
        allow(Account).to receive(:find_in_batches).and_yield([account])
      end

      it 'does not process the account' do
        expect(AutoAssignment::AssignmentJob).not_to receive(:perform_later)

        described_class.new.perform
      end
    end

    context 'with batch processing' do
      it 'processes accounts in batches' do
        accounts = []
        # Create multiple accounts
        5.times do |_i|
          acc = create(:account)
          inb = create(:inbox, account: acc, enable_auto_assignment: true)
          policy = create(:assignment_policy, account: acc)
          create(:inbox_assignment_policy, inbox: inb, assignment_policy: policy)
          allow(acc).to receive(:feature_enabled?).with('assignment_v2').and_return(true)
          allow(inb).to receive(:auto_assignment_v2_enabled?).and_return(true)

          inbox_relation = instance_double(ActiveRecord::Relation)
          allow(acc).to receive(:inboxes).and_return(inbox_relation)
          allow(inbox_relation).to receive(:joins).with(:assignment_policy).and_return(inbox_relation)
          allow(inbox_relation).to receive(:find_in_batches).and_yield([inb])

          accounts << acc
        end

        allow(Account).to receive(:find_in_batches) do |&block|
          accounts.each { |acc| block.call([acc]) }
        end

        expect(Account).to receive(:find_in_batches).and_call_original

        described_class.new.perform
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in the scheduled_jobs queue' do
      expect(described_class.queue_name).to eq('scheduled_jobs')
    end
  end
end
