# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::AssignmentOrchestrator, type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }
  let!(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }
  let(:agent1) { create(:user, account: account) }
  let(:agent2) { create(:user, account: account) }
  let(:orchestrator) { described_class.new(inbox) }

  before do
    create(:inbox_member, inbox: inbox, user: agent1)
    create(:inbox_member, inbox: inbox, user: agent2)
    allow(inbox).to receive(:assignment_v2_enabled?).and_return(true)
  end

  describe '#initialize' do
    it 'sets up orchestrator with inbox and policy' do
      expect(orchestrator.inbox).to eq(inbox)
      expect(orchestrator.policy).to eq(assignment_policy)
    end

    it 'initializes rate limiter when policy exists' do
      expect(orchestrator.instance_variable_get(:@rate_limiter)).to be_present
    end

    it 'initializes metrics tracker' do
      expect(orchestrator.metrics).to be_a(described_class::AssignmentMetrics)
    end
  end

  describe '#assign_conversations' do
    let!(:conversation1) { create(:conversation, inbox: inbox, assignee: nil, status: :open) }
    let!(:conversation2) { create(:conversation, inbox: inbox, assignee: nil, status: :open) }

    context 'when assignment is possible' do
      before do
        allow_any_instance_of(AssignmentV2::RoundRobinSelector).to receive(:select_agent).and_return(agent1)
        allow_any_instance_of(AssignmentV2::RateLimiter).to receive(:agent_within_limits?).and_return(true)
      end

      it 'assigns conversations to agents' do
        expect(orchestrator.assign_conversations(limit: 2)).to eq(2)
        
        expect(conversation1.reload.assignee).to eq(agent1)
        expect(conversation2.reload.assignee).to eq(agent1)
      end

      it 'creates audit logs for assignments' do
        expect { orchestrator.assign_conversations(limit: 2) }.to change { conversation1.messages.activity.count }.by(1)
      end

      it 'triggers assignment notifications' do
        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          'conversation.assigned',
          anything,
          hash_including(conversation: conversation1, assignee: agent1)
        ).once

        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          'conversation.assigned', 
          anything,
          hash_including(conversation: conversation2, assignee: agent1)
        ).once

        orchestrator.assign_conversations(limit: 2)
      end

      it 'records metrics for successful assignments' do
        orchestrator.assign_conversations(limit: 2)
        
        metrics = orchestrator.metrics.instance_variable_get(:@assignments)
        expect(metrics.size).to eq(2)
        expect(metrics.first).to include(
          conversation_id: conversation1.id,
          agent_id: agent1.id,
          policy_id: assignment_policy.id
        )
      end
    end

    context 'when no agent is available' do
      before do
        allow_any_instance_of(AssignmentV2::RoundRobinSelector).to receive(:select_agent).and_return(nil)
      end

      it 'does not assign conversations' do
        expect(orchestrator.assign_conversations(limit: 2)).to eq(0)
        
        expect(conversation1.reload.assignee).to be_nil
        expect(conversation2.reload.assignee).to be_nil
      end
    end

    context 'when rate limiter blocks assignment' do
      before do
        allow_any_instance_of(AssignmentV2::RoundRobinSelector).to receive(:select_agent).and_return(agent1)
        allow_any_instance_of(AssignmentV2::RateLimiter).to receive(:agent_within_limits?).and_return(false)
      end

      it 'does not perform assignment' do
        expect(orchestrator.assign_conversations(limit: 2)).to eq(0)
        
        expect(conversation1.reload.assignee).to be_nil
        expect(conversation2.reload.assignee).to be_nil
      end
    end

    context 'when assignment fails due to database error' do
      before do
        allow_any_instance_of(AssignmentV2::RoundRobinSelector).to receive(:select_agent).and_return(agent1)
        allow_any_instance_of(AssignmentV2::RateLimiter).to receive(:agent_within_limits?).and_return(true)
        allow(conversation1).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'continues with other conversations' do
        expect(Rails.logger).to receive(:error).with(/Assignment failed/)
        
        result = orchestrator.assign_conversations(limit: 2)
        expect(result).to eq(1) # Only conversation2 succeeds
        expect(conversation2.reload.assignee).to eq(agent1)
      end
    end
  end

  describe '#assign_conversation' do
    let(:conversation) { create(:conversation, inbox: inbox, assignee: nil, status: :open) }

    context 'when assignment succeeds' do
      before do
        allow_any_instance_of(AssignmentV2::RoundRobinSelector).to receive(:select_agent).and_return(agent1)
        allow_any_instance_of(AssignmentV2::RateLimiter).to receive(:agent_within_limits?).and_return(true)
      end

      it 'returns true and assigns conversation' do
        expect(orchestrator.assign_conversation(conversation)).to be true
        expect(conversation.reload.assignee).to eq(agent1)
      end
    end

    context 'when conversation is already assigned' do
      let(:conversation) { create(:conversation, inbox: inbox, assignee: agent2, status: :open) }

      it 'returns false without changing assignment' do
        expect(orchestrator.assign_conversation(conversation)).to be false
        expect(conversation.reload.assignee).to eq(agent2)
      end
    end
  end

  describe 'enterprise balanced assignment' do
    let(:enterprise_account) { create(:account) }
    let(:enterprise_inbox) { create(:inbox, account: enterprise_account) }
    let(:balanced_policy) { create(:assignment_policy, account: enterprise_account, assignment_order: :balanced) }
    let!(:enterprise_inbox_policy) { create(:inbox_assignment_policy, inbox: enterprise_inbox, assignment_policy: balanced_policy) }
    let(:enterprise_orchestrator) { described_class.new(enterprise_inbox) }

    before do
      allow(enterprise_inbox).to receive(:assignment_v2_enabled?).and_return(true)
      allow(enterprise_account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)
      stub_const('Enterprise', Module.new)
    end

    it 'uses balanced selector for enterprise accounts' do
      conversation = create(:conversation, inbox: enterprise_inbox, assignee: nil, status: :open)
      
      balanced_selector_double = instance_double('Enterprise::AssignmentV2::BalancedSelector')
      expect(Enterprise::AssignmentV2::BalancedSelector).to receive(:new).with(enterprise_inbox, balanced_policy).and_return(balanced_selector_double)
      expect(balanced_selector_double).to receive(:select_agent).and_return(agent1)
      
      allow_any_instance_of(AssignmentV2::RateLimiter).to receive(:agent_within_limits?).and_return(true)
      
      enterprise_orchestrator.assign_conversation(conversation)
    end
  end

  describe '#can_assign?' do
    it 'returns true when policy is enabled and inbox has auto assignment' do
      expect(orchestrator.send(:can_assign?)).to be true
    end

    it 'returns false when policy is disabled' do
      assignment_policy.update!(enabled: false)
      expect(orchestrator.send(:can_assign?)).to be false
    end

    it 'returns false when inbox auto assignment is disabled' do
      inbox.update!(enable_auto_assignment: false)
      expect(orchestrator.send(:can_assign?)).to be false
    end

    it 'returns false when no policy exists' do
      inbox_assignment_policy.destroy!
      orchestrator_without_policy = described_class.new(inbox)
      expect(orchestrator_without_policy.send(:can_assign?)).to be false
    end
  end

  describe 'conversation prioritization' do
    let!(:oldest_conversation) { create(:conversation, inbox: inbox, assignee: nil, status: :open, created_at: 2.hours.ago) }
    let!(:newest_conversation) { create(:conversation, inbox: inbox, assignee: nil, status: :open, created_at: 1.hour.ago) }

    context 'with earliest_created priority' do
      before do
        assignment_policy.update!(conversation_priority: :earliest_created)
        allow_any_instance_of(AssignmentV2::RoundRobinSelector).to receive(:select_agent).and_return(agent1)
        allow_any_instance_of(AssignmentV2::RateLimiter).to receive(:agent_within_limits?).and_return(true)
      end

      it 'processes oldest conversation first' do
        orchestrator.assign_conversations(limit: 1)
        expect(oldest_conversation.reload.assignee).to eq(agent1)
        expect(newest_conversation.reload.assignee).to be_nil
      end
    end

    context 'with longest_waiting priority' do
      before do
        assignment_policy.update!(conversation_priority: :longest_waiting)
        oldest_conversation.update!(last_activity_at: 3.hours.ago)
        newest_conversation.update!(last_activity_at: 30.minutes.ago)
        
        allow_any_instance_of(AssignmentV2::RoundRobinSelector).to receive(:select_agent).and_return(agent1)
        allow_any_instance_of(AssignmentV2::RateLimiter).to receive(:agent_within_limits?).and_return(true)
      end

      it 'processes conversation with longest wait time first' do
        orchestrator.assign_conversations(limit: 1) 
        expect(oldest_conversation.reload.assignee).to eq(agent1)
        expect(newest_conversation.reload.assignee).to be_nil
      end
    end
  end
end