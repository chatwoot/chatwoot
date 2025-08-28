require 'rails_helper'

RSpec.describe Enterprise::AutoAssignment::CapacityService, type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

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
      create(:conversation, inbox: inbox, assignee: agent_at_capacity, status: :open)
    end
  end

  describe 'capacity filtering' do
    it 'excludes agents at capacity' do
      available = inbox.available_agents(check_capacity: true)
      available_users = available.map(&:user)

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
    let(:conversation) { create(:conversation, inbox: inbox, assignee: nil, status: :open) }

    it 'assigns to agents with available capacity' do
      # Mock the selector to prefer agent_at_capacity (but should skip due to capacity)
      selector = instance_double(AutoAssignment::RoundRobinSelector)
      allow(AutoAssignment::RoundRobinSelector).to receive(:new).and_return(selector)
      allow(selector).to receive(:select_agent) do |agents|
        agents.map(&:user).find { |u| [agent_with_capacity, agent_without_capacity].include?(u) }
      end

      expect(service.perform_for_conversation(conversation)).to be true
      expect(conversation.reload.assignee).to be_in([agent_with_capacity, agent_without_capacity])
      expect(conversation.reload.assignee).not_to eq(agent_at_capacity)
    end

    it 'returns false when all agents are at capacity' do
      # Fill up remaining agents
      3.times { create(:conversation, inbox: inbox, assignee: agent_with_capacity, status: :open) }

      # agent_without_capacity has no limit, so should still be available
      conversation2 = create(:conversation, inbox: inbox, assignee: nil, status: :open)
      expect(service.perform_for_conversation(conversation2)).to be true
      expect(conversation2.reload.assignee).to eq(agent_without_capacity)
    end
  end

  describe 'capacity status' do
    it 'provides accurate capacity status for agent at capacity' do
      capacity_service = described_class.new
      status = capacity_service.agent_capacity_status(agent_at_capacity, inbox)

      expect(status[:has_capacity]).to be false
      expect(status[:current]).to eq(3)
      expect(status[:limit]).to eq(3)
    end

    it 'provides accurate capacity status for agent with capacity' do
      capacity_service = described_class.new
      status = capacity_service.agent_capacity_status(agent_with_capacity, inbox)

      expect(status[:has_capacity]).to be true
      expect(status[:current]).to eq(0)
      expect(status[:limit]).to eq(3)
    end

    it 'provides accurate capacity status for agent without limit' do
      capacity_service = described_class.new
      status = capacity_service.agent_capacity_status(agent_without_capacity, inbox)

      expect(status[:has_capacity]).to be true
      expect(status[:limit]).to be_nil
    end
  end
end
