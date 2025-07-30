# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::AssignmentService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assignment_policy) { create(:assignment_policy, account: account, enabled: true) }
  let!(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }
  let(:service) { described_class.new(inbox) }

  # Create agents
  let!(:agent1) { create(:user, account: account, role: :agent, availability: :online) }
  let!(:agent2) { create(:user, account: account, role: :agent, availability: :online) }
  let!(:agent3) { create(:user, account: account, role: :agent, availability: :offline) }
  
  # Make agents members of inbox
  before do
    create(:inbox_member, inbox: inbox, user: agent1)
    create(:inbox_member, inbox: inbox, user: agent2)
    create(:inbox_member, inbox: inbox, user: agent3)
  end

  describe '#assign_conversation' do
    let(:conversation) { create(:conversation, inbox: inbox, assignee: nil) }

    context 'when policy is enabled' do
      it 'assigns conversation to an available agent' do
        expect(service.assign_conversation(conversation)).to be true
        expect(conversation.reload.assignee).to be_in([agent1, agent2])
      end

      it 'dispatches assignment event' do
        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          'assignee.changed',
          anything,
          hash_including(conversation: conversation, user: anything)
        )
        service.assign_conversation(conversation)
      end

      it 'returns false when no agents are available' do
        agent1.update!(availability: :offline)
        agent2.update!(availability: :offline)
        
        expect(service.assign_conversation(conversation)).to be false
        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'when policy is disabled' do
      before { assignment_policy.update!(enabled: false) }

      it 'does not assign conversation' do
        expect(service.assign_conversation(conversation)).to be false
        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'when conversation is already assigned' do
      before { conversation.update!(assignee: agent1) }

      it 'does not reassign conversation' do
        expect(service.assign_conversation(conversation)).to be false
        expect(conversation.reload.assignee).to eq(agent1)
      end
    end

    context 'with round robin assignment' do
      before { assignment_policy.update!(assignment_order: :round_robin) }

      it 'assigns agents in rotation' do
        conversations = create_list(:conversation, 4, inbox: inbox, assignee: nil)
        
        # Clear any existing round robin cache
        Rails.cache.delete("assignment_v2:round_robin:#{inbox.id}")
        
        assignments = conversations.map do |conv|
          service.assign_conversation(conv)
          conv.reload.assignee
        end

        # Should rotate between available agents
        expect(assignments[0]).to be_in([agent1, agent2])
        expect(assignments[1]).to be_in([agent1, agent2])
        expect(assignments[0]).not_to eq(assignments[1]) # Different agents
        expect(assignments[2]).to eq(assignments[0]) # Back to first agent
        expect(assignments[3]).to eq(assignments[1]) # Back to second agent
      end
    end

    context 'with balanced assignment' do
      before do
        assignment_policy.update!(assignment_order: :balanced)
        # Mock enterprise feature check
        allow(inbox.account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)
      end

      it 'assigns to agent with least conversations' do
        # Create existing assignments
        create_list(:conversation, 3, inbox: inbox, assignee: agent1, status: :open)
        create(:conversation, inbox: inbox, assignee: agent2, status: :open)
        
        new_conversation = create(:conversation, inbox: inbox, assignee: nil)
        
        expect(service.assign_conversation(new_conversation)).to be true
        expect(new_conversation.reload.assignee).to eq(agent2)
      end

      it 'only counts open and pending conversations' do
        # Create resolved conversations (should not count)
        create_list(:conversation, 5, inbox: inbox, assignee: agent1, status: :resolved)
        
        # Create open conversation
        create(:conversation, inbox: inbox, assignee: agent2, status: :open)
        
        new_conversation = create(:conversation, inbox: inbox, assignee: nil)
        
        expect(service.assign_conversation(new_conversation)).to be true
        expect(new_conversation.reload.assignee).to eq(agent1) # Less active conversations
      end
    end

    context 'error handling' do
      it 'returns false and logs error on assignment failure' do
        allow_any_instance_of(Conversation).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        expect(Rails.logger).to receive(:error).with(/Assignment failed/)
        
        expect(service.assign_conversation(conversation)).to be false
      end
    end
  end

  describe '#assign_conversations' do
    let!(:conversations) { create_list(:conversation, 5, inbox: inbox, assignee: nil, status: :open) }

    context 'when policy is enabled' do
      it 'assigns multiple conversations' do
        assigned_count = service.assign_conversations(limit: 3)
        
        expect(assigned_count).to eq(3)
        expect(inbox.conversations.unassigned.count).to eq(2)
      end

      it 'respects conversation priority order' do
        # Create conversations with different timestamps
        old_conversation = create(:conversation, inbox: inbox, assignee: nil, created_at: 1.hour.ago)
        new_conversation = create(:conversation, inbox: inbox, assignee: nil, created_at: 1.minute.ago)
        
        assignment_policy.update!(conversation_priority: :earliest_created)
        
        service.assign_conversations(limit: 1)
        
        expect(old_conversation.reload.assignee).not_to be_nil
        expect(new_conversation.reload.assignee).to be_nil
      end

      it 'handles longest_waiting priority' do
        # Create conversations with different last activity
        inactive_conversation = create(:conversation, inbox: inbox, assignee: nil, last_activity_at: 2.hours.ago)
        active_conversation = create(:conversation, inbox: inbox, assignee: nil, last_activity_at: 5.minutes.ago)
        
        assignment_policy.update!(conversation_priority: :longest_waiting)
        
        service.assign_conversations(limit: 1)
        
        expect(inactive_conversation.reload.assignee).not_to be_nil
        expect(active_conversation.reload.assignee).to be_nil
      end

      it 'returns 0 when no conversations to assign' do
        Conversation.update_all(assignee_id: agent1.id)
        
        expect(service.assign_conversations).to eq(0)
      end
    end

    context 'when policy is disabled' do
      before { assignment_policy.update!(enabled: false) }

      it 'does not assign any conversations' do
        expect(service.assign_conversations).to eq(0)
        expect(inbox.conversations.unassigned.count).to eq(5)
      end
    end
  end

  describe 'enterprise capacity features' do
    let(:capacity_policy) { create(:enterprise_agent_capacity_policy, account: account) }
    let(:conversation) { create(:conversation, inbox: inbox, assignee: nil) }

    before do
      # Mock enterprise availability
      stub_const('Enterprise', Module.new)
      stub_const('Enterprise::AssignmentV2::CapacityManager', Class.new)
      
      allow_any_instance_of(Enterprise::AssignmentV2::CapacityManager).to receive(:get_agent_capacity).and_return(
        { available_capacity: 1 }
      )
      
      allow(assignment_policy).to receive(:capacity_filtering_enabled?).and_return(true)
      allow(inbox.account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)
    end

    it 'applies capacity filters when available' do
      # Mock capacity limits
      allow_any_instance_of(Enterprise::AssignmentV2::CapacityManager).to receive(:get_agent_capacity)
        .with(agent1, inbox).and_return({ available_capacity: 0 })
      allow_any_instance_of(Enterprise::AssignmentV2::CapacityManager).to receive(:get_agent_capacity)
        .with(agent2, inbox).and_return({ available_capacity: 5 })
      
      expect(service.assign_conversation(conversation)).to be true
      expect(conversation.reload.assignee).to eq(agent2) # Only agent with capacity
    end

    it 'skips capacity filtering when enterprise not available' do
      allow(assignment_policy).to receive(:capacity_filtering_enabled?).and_return(false)
      
      expect(service.assign_conversation(conversation)).to be true
      expect(conversation.reload.assignee).to be_in([agent1, agent2])
    end
  end

  describe 'cache management' do
    it 'uses cache for round robin state' do
      assignment_policy.update!(assignment_order: :round_robin)
      cache_key = "assignment_v2:round_robin:#{inbox.id}"
      
      # First assignment
      conversation1 = create(:conversation, inbox: inbox, assignee: nil)
      service.assign_conversation(conversation1)
      
      # Check cache was written
      expect(Rails.cache.read(cache_key)).not_to be_nil
      
      # Second assignment should use cached state
      conversation2 = create(:conversation, inbox: inbox, assignee: nil)
      expect(Rails.cache).to receive(:read).with(cache_key).and_call_original
      
      service.assign_conversation(conversation2)
    end
  end

  describe 'edge cases' do
    it 'handles inbox without policy gracefully' do
      inbox_assignment_policy.destroy!
      conversation = create(:conversation, inbox: inbox, assignee: nil)
      
      expect(service.assign_conversation(conversation)).to be false
    end

    it 'handles empty agent list' do
      InboxMember.destroy_all
      conversation = create(:conversation, inbox: inbox, assignee: nil)
      
      expect(service.assign_conversation(conversation)).to be false
    end

    it 'filters out agents without inbox membership' do
      non_member_agent = create(:user, account: account, role: :agent, availability: :online)
      conversation = create(:conversation, inbox: inbox, assignee: nil)
      
      expect(service.assign_conversation(conversation)).to be true
      expect(conversation.reload.assignee).not_to eq(non_member_agent)
    end
  end
end