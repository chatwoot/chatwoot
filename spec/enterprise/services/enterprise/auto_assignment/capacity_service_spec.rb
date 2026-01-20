require 'rails_helper'

RSpec.describe Enterprise::AutoAssignment::CapacityService, type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }

  # Assignment policy with rate limiting
  let(:assignment_policy) do
    create(:assignment_policy,
           account: account,
           enabled: true,
           fair_distribution_limit: 5,
           fair_distribution_window: 3600)
  end

  # Agent capacity policy
  let(:agent_capacity_policy) do
    create(:agent_capacity_policy, account: account, name: 'Limited Capacity')
  end

  # Agents with different capacity settings
  let(:agent_with_capacity) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent_without_capacity) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent_at_capacity) { create(:user, account: account, role: :agent, availability: :online) }

  before do
    # Create inbox assignment policy
    create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)

    # Set inbox capacity limit
    create(:inbox_capacity_limit,
           agent_capacity_policy: agent_capacity_policy,
           inbox: inbox,
           conversation_limit: 3)

    # Assign capacity policy to specific agents
    agent_with_capacity.account_users.find_by(account: account)
                       .update!(agent_capacity_policy: agent_capacity_policy)

    agent_at_capacity.account_users.find_by(account: account)
                     .update!(agent_capacity_policy: agent_capacity_policy)

    # Create inbox members
    create(:inbox_member, inbox: inbox, user: agent_with_capacity)
    create(:inbox_member, inbox: inbox, user: agent_without_capacity)
    create(:inbox_member, inbox: inbox, user: agent_at_capacity)

    # Mock online status
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({
                                                                             agent_with_capacity.id.to_s => 'online',
                                                                             agent_without_capacity.id.to_s => 'online',
                                                                             agent_at_capacity.id.to_s => 'online'
                                                                           })

    # Enable assignment_v2 feature
    allow(account).to receive(:feature_enabled?).with('assignment_v2').and_return(true)

    # Create existing assignments for agent_at_capacity (at limit)
    3.times do
      create(:conversation, inbox: inbox, assignee: agent_at_capacity, status: 'open')
    end
  end

  describe 'capacity filtering' do
    it 'excludes agents at capacity' do
      # Get available agents respecting capacity
      capacity_service = described_class.new
      online_agents = inbox.available_agents
      filtered_agents = online_agents.select do |inbox_member|
        capacity_service.agent_has_capacity?(inbox_member.user, inbox)
      end
      available_users = filtered_agents.map(&:user)

      expect(available_users).to include(agent_with_capacity)
      expect(available_users).to include(agent_without_capacity) # No capacity policy = unlimited
      expect(available_users).not_to include(agent_at_capacity) # At capacity limit
    end

    it 'respects inbox-specific capacity limits' do
      capacity_service = described_class.new

      expect(capacity_service.agent_has_capacity?(agent_with_capacity, inbox)).to be true
      expect(capacity_service.agent_has_capacity?(agent_without_capacity, inbox)).to be true
      expect(capacity_service.agent_has_capacity?(agent_at_capacity, inbox)).to be false
    end
  end

  describe 'assignment with capacity' do
    let(:service) { AutoAssignment::AssignmentService.new(inbox: inbox) }

    # Disable auto-assignment for test setup
    around do |example|
      inbox.update!(enable_auto_assignment: false)
      example.run
      inbox.update!(enable_auto_assignment: true)
    end

    it 'assigns to agents with available capacity' do
      # Create conversation WITHOUT auto-assignment
      conversation = create(:conversation, inbox: inbox, assignee: nil, status: 'open')

      # Verify conversation is actually unassigned
      conversation.reload
      expect(conversation.assignee).to be_nil, "Conversation should be unassigned but has assignee_id: #{conversation.assignee_id}"

      # Re-enable auto-assignment for the service
      inbox.update!(enable_auto_assignment: true)

      # Verify unassigned conversations are found
      unassigned_count = inbox.conversations.where(assignee_id: nil, status: 'open').count
      expect(unassigned_count).to eq(1), "Should find 1 unassigned conversation, found #{unassigned_count}"

      assigned_count = service.perform_bulk_assignment(limit: 1)

      expect(assigned_count).to eq(1)

      conversation.reload
      expect(conversation.assignee).not_to be_nil
      expect(conversation.assignee).to be_in([agent_with_capacity, agent_without_capacity])
      expect(conversation.assignee).not_to eq(agent_at_capacity)
    end

    it 'assigns when only agent without capacity policy is available' do
      # Fill up agent_with_capacity
      3.times { create(:conversation, inbox: inbox, assignee: agent_with_capacity, status: 'open') }

      # Create unassigned conversation
      conversation = create(:conversation, inbox: inbox, assignee: nil, status: 'open')
      conversation.reload

      # Verify conversation is unassigned
      expect(conversation.assignee).to be_nil

      # Re-enable auto-assignment
      inbox.update!(enable_auto_assignment: true)

      assigned_count = service.perform_bulk_assignment(limit: 1)

      expect(assigned_count).to eq(1)
      expect(conversation.reload.assignee).to eq(agent_without_capacity)
    end

    it 'returns zero when all capacity-limited agents are at capacity' do
      # Fill up all agents with capacity policies
      3.times { create(:conversation, inbox: inbox, assignee: agent_with_capacity, status: 'open') }

      # Remove agent_without_capacity from inbox (to test zero assignment)
      inbox.inbox_members.find_by(user: agent_without_capacity).destroy

      conversation = create(:conversation, inbox: inbox, assignee: nil, status: 'open')
      conversation.reload

      # Verify conversation is unassigned
      expect(conversation.assignee).to be_nil

      # Re-enable auto-assignment
      inbox.update!(enable_auto_assignment: true)

      assigned_count = service.perform_bulk_assignment(limit: 1)

      expect(assigned_count).to eq(0)
      expect(conversation.reload.assignee).to be_nil
    end
  end
end
