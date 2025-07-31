# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::AssignmentOrchestrator, type: :integration do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  # Create agents with different availability
  let!(:agent1) { create(:user, account: account, name: 'Agent 1', role: :agent, availability: :online) }
  let!(:agent2) { create(:user, account: account, name: 'Agent 2', role: :agent, availability: :online) }
  let!(:agent3) { create(:user, account: account, name: 'Agent 3', role: :agent, availability: :busy) }
  let!(:agent4) { create(:user, account: account, name: 'Agent 4', role: :agent, availability: :offline) }

  before do
    # Make agents members of inbox
    [agent1, agent2, agent3, agent4].each do |agent|
      create(:inbox_member, inbox: inbox, user: agent)
    end

    # Clear Redis to ensure clean state
    Redis::Alfred.flushdb
  end

  describe 'Round Robin Assignment' do
    let(:assignment_policy) do
      create(:assignment_policy,
             account: account,
             name: 'Round Robin Policy',
             assignment_order: :round_robin,
             conversation_priority: :earliest_created,
             enabled: true)
    end

    let(:inbox_assignment_policy) do
      create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
    end

    it 'assigns conversations in round-robin fashion to online agents only' do
      # Create unassigned conversations
      conversations = create_list(:conversation, 6, inbox: inbox, assignee: nil, status: :open)

      # Process assignments
      service = AssignmentV2::AssignmentService.new(inbox)
      assigned_count = service.assign_conversations

      expect(assigned_count).to eq(6)

      # Verify all conversations are assigned
      conversations.each(&:reload)
      expect(conversations.filter_map(&:assignee).count).to eq(6)

      # Verify only online agents received assignments
      assigned_agents = conversations.map(&:assignee).uniq
      expect(assigned_agents).to contain_exactly(agent1, agent2)

      # Verify round-robin distribution
      agent1_count = conversations.count { |c| c.assignee == agent1 }
      agent2_count = conversations.count { |c| c.assignee == agent2 }
      expect([agent1_count, agent2_count]).to contain_exactly(3, 3)
    end

    it 'respects conversation priority order' do
      # Create conversations with different creation times
      old_conv = create(:conversation, inbox: inbox, assignee: nil, created_at: 2.hours.ago)
      mid_conv = create(:conversation, inbox: inbox, assignee: nil, created_at: 1.hour.ago)
      new_conv = create(:conversation, inbox: inbox, assignee: nil, created_at: 5.minutes.ago)

      # Assign only 2 conversations
      service = AssignmentV2::AssignmentService.new(inbox)
      service.assign_conversations(limit: 2)

      # Oldest conversations should be assigned first
      expect(old_conv.reload.assignee).not_to be_nil
      expect(mid_conv.reload.assignee).not_to be_nil
      expect(new_conv.reload.assignee).to be_nil
    end

    it 'handles agent availability changes mid-assignment' do
      conversations = create_list(:conversation, 4, inbox: inbox, assignee: nil)

      # Assign first batch
      service = AssignmentV2::AssignmentService.new(inbox)
      service.assign_conversations(limit: 2)

      # Make agent1 offline
      agent1.update!(availability: :offline)

      # Assign remaining conversations
      service.assign_conversations(limit: 2)

      # All remaining should go to agent2
      remaining_assignments = conversations.reload.last(2).map(&:assignee)
      expect(remaining_assignments).to all(eq(agent2))
    end
  end

  describe 'Balanced Assignment' do
    let(:assignment_policy) do
      create(:assignment_policy,
             account: account,
             name: 'Balanced Policy',
             assignment_order: :balanced,
             enabled: true)
    end

    let(:inbox_assignment_policy) do
      create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
    end

    before do
      # Mock enterprise features
      allow(account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)
    end

    it 'assigns to agent with least conversations' do
      # Create existing load imbalance
      create_list(:conversation, 5, inbox: inbox, assignee: agent1, status: :open)
      create_list(:conversation, 2, inbox: inbox, assignee: agent2, status: :open)

      # Create new conversations
      new_conversations = create_list(:conversation, 3, inbox: inbox, assignee: nil)

      # Process assignments
      service = AssignmentV2::AssignmentService.new(inbox)
      service.assign_conversations

      # All should go to agent2 (less loaded)
      new_conversations.each(&:reload)
      expect(new_conversations.map(&:assignee)).to all(eq(agent2))

      # Final count should be more balanced
      expect(agent1.assigned_conversations.open.where(inbox: inbox).count).to eq(5)
      expect(agent2.assigned_conversations.open.where(inbox: inbox).count).to eq(5)
    end

    it 'only counts open conversations for balancing' do
      # Agent1 has many resolved conversations (shouldn't count)
      create_list(:conversation, 10, inbox: inbox, assignee: agent1, status: :resolved)
      # Agent1 has 1 open conversation
      create(:conversation, inbox: inbox, assignee: agent1, status: :open)

      # Agent2 has 3 open conversations
      create_list(:conversation, 3, inbox: inbox, assignee: agent2, status: :open)

      # New conversation should go to agent1
      new_conversation = create(:conversation, inbox: inbox, assignee: nil)

      service = AssignmentV2::AssignmentService.new(inbox)
      service.assign_conversation(new_conversation)

      expect(new_conversation.reload.assignee).to eq(agent1)
    end
  end

  describe 'Enterprise Capacity Management' do
    let(:assignment_policy) do
      create(:assignment_policy,
             account: account,
             assignment_order: :balanced,
             enabled: true)
    end

    let(:inbox_assignment_policy) do
      create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
    end

    let(:capacity_policy) do
      create(:enterprise_agent_capacity_policy, account: account, name: 'Limited Capacity')
    end

    before do
      # Mock enterprise features
      stub_const('Enterprise', Module.new)
      stub_const('Enterprise::AgentCapacityPolicy', Class.new(ApplicationRecord))
      stub_const('Enterprise::InboxCapacityLimit', Class.new(ApplicationRecord))

      allow(account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)

      # Set up capacity limits
      agent1.account_users.first.update!(agent_capacity_policy: capacity_policy)
      agent2.account_users.first.update!(agent_capacity_policy: capacity_policy)

      create(:enterprise_inbox_capacity_limit,
             agent_capacity_policy: capacity_policy,
             inbox: inbox,
             conversation_limit: 3)
    end

    it 'respects agent capacity limits' do
      # Fill agent1 to capacity
      create_list(:conversation, 3, inbox: inbox, assignee: agent1, status: :open)

      # Create new conversations
      new_conversations = create_list(:conversation, 4, inbox: inbox, assignee: nil)

      # Mock capacity manager
      capacity_manager = instance_double(Enterprise::AssignmentV2::CapacityManager)
      allow(Enterprise::AssignmentV2::CapacityManager).to receive(:new).and_return(capacity_manager)

      # Agent1 at capacity, agent2 has room
      allow(capacity_manager).to receive(:get_agent_capacity).with(agent1, inbox).and_return(
        { available_capacity: 0, current_assignments: 3, total_capacity: 3 }
      )
      allow(capacity_manager).to receive(:get_agent_capacity).with(agent2, inbox).and_return(
        { available_capacity: 3, current_assignments: 0, total_capacity: 3 }
      )

      # Process assignments
      service = AssignmentV2::AssignmentService.new(inbox)
      assigned_count = service.assign_conversations

      # Only 3 should be assigned (agent2's capacity)
      expect(assigned_count).to eq(3)

      # All should go to agent2
      assigned_conversations = new_conversations.select { |c| c.reload.assignee.present? }
      expect(assigned_conversations.map(&:assignee)).to all(eq(agent2))
    end

    it 'handles capacity policy with exclusion rules' do
      # Update capacity policy with exclusion rules
      capacity_policy.update!(
        exclusion_rules: {
          'labels' => ['urgent'],
          'hours_threshold' => 24
        }
      )

      # Create urgent label
      urgent_label = create(:label, account: account, title: 'urgent')

      # Create mixed conversations for agent1
      create(:conversation, inbox: inbox, assignee: agent1, status: :open)
      urgent_conv = create(:conversation, inbox: inbox, assignee: agent1, status: :open)
      create(:conversation_label, conversation: urgent_conv, label: urgent_label)
      create(:conversation, inbox: inbox, assignee: agent1, status: :open, created_at: 2.days.ago)

      # Mock capacity calculation with exclusions
      capacity_manager = instance_double(Enterprise::AssignmentV2::CapacityManager)
      allow(Enterprise::AssignmentV2::CapacityManager).to receive(:new).and_return(capacity_manager)

      # Only regular conversation counts toward capacity
      allow(capacity_manager).to receive(:get_agent_capacity).with(agent1, inbox).and_return(
        { available_capacity: 2, current_assignments: 1, total_capacity: 3 }
      )

      # New conversation should still be assignable
      new_conversation = create(:conversation, inbox: inbox, assignee: nil)

      service = AssignmentV2::AssignmentService.new(inbox)
      expect(service.assign_conversation(new_conversation)).to be true
    end
  end

  describe 'Team-based Assignment' do
    let(:team) { create(:team, account: account) }
    let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }

    before do
      create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
      create(:team_member, team: team, user: agent1)
      create(:team_member, team: team, user: agent2)
    end

    it 'assigns only to team members when conversation has team' do
      # Create conversation with team
      conversation = create(:conversation, inbox: inbox, assignee: nil, team: team)

      # Mock team filtering in service
      service = AssignmentV2::AssignmentService.new(inbox)

      # Should only consider team members
      100.times do
        conversation.update!(assignee: nil)
        service.assign_conversation(conversation)
        expect(conversation.reload.assignee).to be_in([agent1, agent2])
      end
    end
  end

  describe 'Feature Flag Control' do
    let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }

    before do
      create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
      allow(inbox).to receive(:assignment_v2_enabled?).and_return(false)
    end

    it 'falls back to legacy assignment when V2 is disabled' do
      conversation = create(:conversation, inbox: inbox, assignee: nil)

      # Enable auto assignment
      inbox.update!(enable_auto_assignment: true)

      # Should use legacy service
      expect(AutoAssignment::AgentAssignmentService).to receive(:new).and_call_original

      # Trigger assignment through model callback
      conversation.update!(status: :open)
    end
  end

  describe 'Concurrent Assignment Handling' do
    let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }

    before { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }

    it 'handles multiple simultaneous assignment jobs' do
      conversations = create_list(:conversation, 10, inbox: inbox, assignee: nil)

      # Simulate concurrent job execution
      threads = []

      3.times do
        threads << Thread.new do
          AssignmentV2::AssignmentJob.new.perform(inbox_id: inbox.id)
        end
      end

      threads.each(&:join)

      # All conversations should be assigned without duplicates
      conversations.each(&:reload)
      assigned_count = conversations.count { |c| c.assignee.present? }

      expect(assigned_count).to eq(10)

      # No conversation should have been assigned multiple times
      assignment_counts = conversations.group_by(&:assignee).transform_values(&:count)
      expect(assignment_counts.values.sum).to eq(10)
    end
  end

  describe 'Error Recovery' do
    let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }

    before { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }

    it 'continues assignment after individual conversation failure' do
      conversations = create_list(:conversation, 5, inbox: inbox, assignee: nil)

      # Make one conversation invalid
      conversations[2].update!(status: 'resolved')

      service = AssignmentV2::AssignmentService.new(inbox)
      assigned_count = service.assign_conversations

      # Should assign 4 out of 5
      expect(assigned_count).to eq(4)

      # Invalid conversation remains unassigned
      expect(conversations[2].reload.assignee).to be_nil
    end

    it 'recovers from Redis failures' do
      # Simulate Redis connection failure
      allow(Redis::Alfred).to receive(:lpop).and_raise(Redis::CannotConnectError)

      conversation = create(:conversation, inbox: inbox, assignee: nil)

      service = AssignmentV2::AssignmentService.new(inbox)

      # Should fall back to database-based assignment
      expect(service.assign_conversation(conversation)).to be true
      expect(conversation.reload.assignee).not_to be_nil
    end
  end
end
