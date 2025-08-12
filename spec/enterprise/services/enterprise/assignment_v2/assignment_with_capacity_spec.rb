# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Assignment with Capacity' do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }

  let(:agent1) { create(:user, accounts: [account]) }
  let(:agent2) { create(:user, accounts: [account]) }
  let(:account_user1) { AccountUser.find_by(account: account, user: agent1) }
  let(:account_user2) { AccountUser.find_by(account: account, user: agent2) }

  let(:capacity_policy) do
    Enterprise::AgentCapacityPolicy.create!(
      account: account,
      name: 'Test Capacity Policy',
      exclusion_rules: { 'overall_capacity' => 5 }
    )
  end

  let!(:inbox_capacity_limit) do
    Enterprise::InboxCapacityLimit.create!(
      agent_capacity_policy: capacity_policy,
      inbox: inbox,
      conversation_limit: 3
    )
  end

  before do
    # Create and setup assignment policy for the inbox
    @assignment_policy = create(:assignment_policy, account: account, enabled: true)
    create(:inbox_assignment_policy, inbox: inbox, assignment_policy: @assignment_policy)

    # Add agents to inbox
    create(:inbox_member, inbox: inbox, user: agent1)
    create(:inbox_member, inbox: inbox, user: agent2)

    # Set agents online using presence and status
    OnlineStatusTracker.update_presence(account.id, 'User', agent1.id)
    OnlineStatusTracker.update_presence(account.id, 'User', agent2.id)
    OnlineStatusTracker.set_status(account.id, agent1.id, 'online')
    OnlineStatusTracker.set_status(account.id, agent2.id, 'online')

    # Also set account_user availability
    account_user1.update!(availability: 'online')
    account_user2.update!(availability: 'online')

    # Assign capacity policy to agent1 only
    account_user1.update!(agent_capacity_policy: capacity_policy)
  end

  describe 'capacity-based agent filtering' do
    context 'when agent has capacity' do
      it 'includes agent in available agents' do
        available_agents = inbox.available_agents(check_capacity: true)
        expect(available_agents.map(&:user)).to include(agent1, agent2)
      end
    end

    context 'when agent reaches inbox capacity limit' do
      before do
        # Create 3 conversations for agent1 (at inbox limit)
        create_list(:conversation, 3, account: account, inbox: inbox, assignee: agent1, status: :open)
      end

      it 'excludes agent from available agents for that inbox' do
        available_agents = inbox.available_agents(check_capacity: true)
        expect(available_agents.map(&:user)).not_to include(agent1)
        expect(available_agents.map(&:user)).to include(agent2)
      end
    end

    context 'when agent reaches overall capacity limit' do
      before do
        # Create 5 conversations for agent1 (at overall limit)
        create_list(:conversation, 5, account: account, assignee: agent1, status: :open)
      end

      it 'excludes agent from all inbox assignments' do
        available_agents = inbox.available_agents(check_capacity: true)
        expect(available_agents.map(&:user)).not_to include(agent1)
        expect(available_agents.map(&:user)).to include(agent2)
      end
    end

    context 'when capacity policy is not applicable (time exclusion)' do
      before do
        capacity_policy.update!(exclusion_rules: {
                                  'overall_capacity' => 5,
                                  'hours' => [Time.current.hour]
                                })
        # Create 5 conversations for agent1 (would be at limit if policy was active)
        create_list(:conversation, 5, account: account, assignee: agent1, status: :open)
      end

      it 'includes agent in available agents' do
        available_agents = inbox.available_agents(check_capacity: true)
        expect(available_agents.map(&:user)).to include(agent1, agent2)
      end
    end
  end

  describe 'capacity-aware assignment' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open, assignee: nil) }

    context 'when agents have capacity' do
      it 'both agents are available for assignment' do
        available = inbox.available_agents(check_capacity: true)
        expect(available.map(&:user)).to include(agent1, agent2)
      end
    end

    context 'when one agent is at capacity' do
      before do
        # Agent1 at inbox capacity
        create_list(:conversation, 3, account: account, inbox: inbox, assignee: agent1, status: :open)
      end

      it 'only agent with capacity is available' do
        available = inbox.available_agents(check_capacity: true)
        expect(available.map(&:user)).not_to include(agent1)
        expect(available.map(&:user)).to include(agent2)
      end
    end

    context 'when all agents are at capacity' do
      before do
        # Both agents at capacity
        account_user2.update!(agent_capacity_policy: capacity_policy)
        create_list(:conversation, 3, account: account, inbox: inbox, assignee: agent1, status: :open)
        create_list(:conversation, 3, account: account, inbox: inbox, assignee: agent2, status: :open)
      end

      it 'no agents are available' do
        available = inbox.available_agents(check_capacity: true)
        expect(available).to be_empty
      end
    end
  end
end
