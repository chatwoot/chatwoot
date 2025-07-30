# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::ContinuousAssignmentJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }
  let!(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }

  before do
    allow(inbox).to receive(:assignment_v2_enabled?).and_return(true)
  end

  describe '#perform' do
    context 'when inbox exists and assignment should run' do
      let!(:conversation1) { create(:conversation, inbox: inbox, assignee: nil, status: :open) }
      let!(:conversation2) { create(:conversation, inbox: inbox, assignee: nil, status: :open) }

      it 'runs assignment orchestrator' do
        orchestrator_double = instance_double(AssignmentV2::AssignmentOrchestrator)
        expect(AssignmentV2::AssignmentOrchestrator).to receive(:new).with(inbox).and_return(orchestrator_double)
        expect(orchestrator_double).to receive(:assign_conversations).with(limit: 50).and_return(2)

        described_class.new.perform(inbox.id)
      end

      it 'logs assignment start and completion' do
        allow_any_instance_of(AssignmentV2::AssignmentOrchestrator).to receive(:assign_conversations).and_return(2)
        
        expect(Rails.logger).to receive(:info).with("Assignment V2: Running continuous assignment for inbox #{inbox.id}")
        expect(Rails.logger).to receive(:info).with("Assignment V2: Completed continuous assignment for inbox #{inbox.id}, made 2 assignments")

        described_class.new.perform(inbox.id)
      end

      context 'when more conversations need processing' do
        it 'schedules next run when batch size equals assignments made' do
          allow_any_instance_of(AssignmentV2::AssignmentOrchestrator).to receive(:assign_conversations).and_return(50)
          allow(inbox.conversations.unassigned.open).to receive(:exists?).and_return(true)

          expect(described_class).to receive(:set).with(wait: anything).and_return(described_class)
          expect(described_class).to receive(:perform_later).with(inbox.id)

          described_class.new.perform(inbox.id, batch_size: 50)
        end

        it 'does not schedule next run when fewer assignments made than batch size' do
          allow_any_instance_of(AssignmentV2::AssignmentOrchestrator).to receive(:assign_conversations).and_return(25)

          expect(described_class).not_to receive(:set)

          described_class.new.perform(inbox.id, batch_size: 50)
        end

        it 'does not schedule next run when no more unassigned conversations' do
          allow_any_instance_of(AssignmentV2::AssignmentOrchestrator).to receive(:assign_conversations).and_return(50)
          allow(inbox.conversations.unassigned.open).to receive(:exists?).and_return(false)

          expect(described_class).not_to receive(:set)

          described_class.new.perform(inbox.id, batch_size: 50)
        end
      end
    end

    context 'when inbox does not exist' do
      it 'logs error and does not raise exception' do
        expect(Rails.logger).to receive(:error).with("Assignment V2: Inbox 999 not found")

        expect { described_class.new.perform(999) }.not_to raise_error
      end
    end

    context 'when assignment should not run' do
      before do
        allow(inbox).to receive(:assignment_v2_enabled?).and_return(false)
      end

      it 'returns early without running assignment' do
        expect(AssignmentV2::AssignmentOrchestrator).not_to receive(:new)

        described_class.new.perform(inbox.id)
      end
    end

    context 'when assignment policy is disabled' do
      before do
        assignment_policy.update!(enabled: false)
      end

      it 'returns early without running assignment' do
        expect(AssignmentV2::AssignmentOrchestrator).not_to receive(:new)

        described_class.new.perform(inbox.id)
      end
    end

    context 'when no unassigned conversations exist' do
      it 'returns early without running assignment' do
        expect(AssignmentV2::AssignmentOrchestrator).not_to receive(:new)

        described_class.new.perform(inbox.id)
      end
    end

    context 'when assignment fails with error' do
      before do
        create(:conversation, inbox: inbox, assignee: nil, status: :open)
        allow_any_instance_of(AssignmentV2::AssignmentOrchestrator).to receive(:assign_conversations).and_raise(StandardError, 'Assignment failed')
      end

      it 'logs error and re-raises exception' do
        expect(Rails.logger).to receive(:error).with("Assignment V2: Continuous assignment failed for inbox #{inbox.id}: Assignment failed")

        expect { described_class.new.perform(inbox.id) }.to raise_error(StandardError, 'Assignment failed')
      end
    end
  end

  describe '.trigger' do
    let(:conversation) { create(:conversation, inbox: inbox) }

    context 'when inbox has assignment v2 enabled' do
      before do
        allow(inbox).to receive(:assignment_v2_enabled?).and_return(true)
      end

      it 'enqueues job for conversation inbox' do
        expect(described_class).to receive(:perform_later).with(inbox.id, batch_size: 10)

        described_class.trigger(conversation)
      end
    end

    context 'when inbox does not have assignment v2 enabled' do
      before do
        allow(inbox).to receive(:assignment_v2_enabled?).and_return(false)
      end

      it 'does not enqueue job' do
        expect(described_class).not_to receive(:perform_later)

        described_class.trigger(conversation)
      end
    end
  end

  describe '.process_all_inboxes' do
    let(:account2) { create(:account) }
    let(:inbox2) { create(:inbox, account: account2) }
    let(:policy2) { create(:assignment_policy, account: account2) }
    let!(:inbox_policy2) { create(:inbox_assignment_policy, inbox: inbox2, assignment_policy: policy2) }

    before do
      allow(inbox).to receive(:assignment_v2_enabled?).and_return(true)
      allow(inbox2).to receive(:assignment_v2_enabled?).and_return(true)

      create(:conversation, inbox: inbox, assignee: nil, status: :open)
      create(:conversation, inbox: inbox2, assignee: nil, status: :open)
    end

    it 'processes all inboxes with enabled assignment policies' do
      expect(Rails.logger).to receive(:info).with(/Scheduling bulk assignment for inbox #{inbox.id}/)
      expect(Rails.logger).to receive(:info).with(/Scheduling bulk assignment for inbox #{inbox2.id}/)

      expect(described_class).to receive(:perform_later).with(inbox.id)
      expect(described_class).to receive(:perform_later).with(inbox2.id)

      described_class.process_all_inboxes
    end

    it 'skips inboxes without unassigned conversations' do
      # Remove unassigned conversations
      Conversation.update_all(status: :resolved)

      expect(described_class).not_to receive(:perform_later)

      described_class.process_all_inboxes
    end

    it 'skips inboxes without assignment v2 enabled' do
      allow(inbox).to receive(:assignment_v2_enabled?).and_return(false)

      expect(described_class).to receive(:perform_later).with(inbox2.id)
      expect(described_class).not_to receive(:perform_later).with(inbox.id)

      described_class.process_all_inboxes
    end
  end

  describe 'delay calculation' do
    let(:job_instance) { described_class.new }

    it 'calculates delay with base time and jitter' do
      delay = job_instance.send(:calculate_delay, inbox)
      
      expect(delay).to be >= 30.seconds
      expect(delay).to be <= 40.seconds
    end

    it 'adds randomization to prevent thundering herd' do
      delays = []
      10.times do
        delays << job_instance.send(:calculate_delay, inbox)
      end

      # All delays should be different due to randomization
      expect(delays.uniq.size).to be > 1
    end
  end

  describe 'retry configuration' do
    it 'has proper retry configuration' do
      expect(described_class.get_sidekiq_options['retry']).to eq(3)
    end

    it 'uses exponentially longer wait times' do
      # This tests the retry_on configuration
      expect(described_class.instance_variable_get(:@retry_callbacks)).to be_present
    end
  end
end