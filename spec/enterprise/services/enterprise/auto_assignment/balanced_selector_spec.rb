require 'rails_helper'

RSpec.describe Enterprise::AutoAssignment::BalancedSelector do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:selector) { described_class.new(inbox: inbox) }
  let(:agent1) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent2) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent3) { create(:user, account: account, role: :agent, availability: :online) }

  before do
    @member1 = create(:inbox_member, inbox: inbox, user: agent1)
    @member2 = create(:inbox_member, inbox: inbox, user: agent2)
    @member3 = create(:inbox_member, inbox: inbox, user: agent3)
  end

  describe '#select_agent' do
    context 'when selecting based on workload' do
      let(:available_agents) { [@member1, @member2, @member3] }

      it 'selects the agent with least open conversations' do
        # Agent1 has 3 open conversations
        3.times { create(:conversation, inbox: inbox, assignee: agent1, status: 'open') }
        
        # Agent2 has 1 open conversation
        create(:conversation, inbox: inbox, assignee: agent2, status: 'open')
        
        # Agent3 has 2 open conversations
        2.times { create(:conversation, inbox: inbox, assignee: agent3, status: 'open') }
        
        selected_agent = selector.select_agent(available_agents)
        
        # Should select agent2 as they have the least conversations
        expect(selected_agent).to eq(agent2)
      end

      it 'considers only open conversations' do
        # Agent1 has 1 open and 3 resolved conversations
        create(:conversation, inbox: inbox, assignee: agent1, status: 'open')
        3.times { create(:conversation, inbox: inbox, assignee: agent1, status: 'resolved') }
        
        # Agent2 has 2 open conversations
        2.times { create(:conversation, inbox: inbox, assignee: agent2, status: 'open') }
        
        selected_agent = selector.select_agent([member1, @member2])
        
        # Should select agent1 as they have fewer open conversations
        expect(selected_agent).to eq(agent1)
      end

      it 'uses round robin as fallback when agents have equal workload' do
        # All agents have same number of conversations
        [@member1, @member2, @member3].each do |member|
          create(:conversation, inbox: inbox, assignee: member.user, status: 'open')
        end
        
        round_robin_service = instance_double(AutoAssignment::InboxRoundRobinService)
        allow(AutoAssignment::InboxRoundRobinService).to receive(:new).and_return(round_robin_service)
        
        expect(round_robin_service).to receive(:available_agent).with(
          allowed_agent_ids: [agent1.id.to_s, agent2.id.to_s, agent3.id.to_s]
        )
        
        selector.select_agent(available_agents)
      end
    end

    context 'when no agents are available' do
      it 'returns nil' do
        selected_agent = selector.select_agent([])
        expect(selected_agent).to be_nil
      end
    end

    context 'when one agent is available' do
      it 'returns that agent' do
        selected_agent = selector.select_agent([@member1])
        expect(selected_agent).to eq(agent1)
      end
    end

    context 'with new agents (no conversations)' do
      it 'prioritizes agents with no conversations' do
        # Agent1 and 2 have conversations
        create(:conversation, inbox: inbox, assignee: agent1, status: 'open')
        create(:conversation, inbox: inbox, assignee: agent2, status: 'open')
        
        # Agent3 is new with no conversations
        selected_agent = selector.select_agent(available_agents)
        
        expect(selected_agent).to eq(agent3)
      end
    end
  end
end