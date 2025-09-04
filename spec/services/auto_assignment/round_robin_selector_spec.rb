require 'rails_helper'

RSpec.describe AutoAssignment::RoundRobinSelector do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:selector) { described_class.new(inbox: inbox) }
  let(:agent1) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent2) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent3) { create(:user, account: account, role: :agent, availability: :online) }
  let(:member1) { create(:inbox_member, inbox: inbox, user: agent1) }
  let(:member2) { create(:inbox_member, inbox: inbox, user: agent2) }
  let(:member3) { create(:inbox_member, inbox: inbox, user: agent3) }

  describe '#select_agent' do
    context 'when agents are available' do
      let(:available_agents) { [member1, member2, member3] }

      it 'returns an agent from the available list' do
        selected_agent = selector.select_agent(available_agents)

        expect(selected_agent).not_to be_nil
        expect([agent1, agent2, agent3]).to include(selected_agent)
      end

      it 'uses round robin service for selection' do
        round_robin_service = instance_double(AutoAssignment::InboxRoundRobinService)
        allow(AutoAssignment::InboxRoundRobinService).to receive(:new).and_return(round_robin_service)

        expect(round_robin_service).to receive(:available_agent).with(
          allowed_agent_ids: [agent1.id.to_s, agent2.id.to_s, agent3.id.to_s]
        ).and_return(agent1)

        selected_agent = selector.select_agent(available_agents)
        expect(selected_agent).to eq(agent1)
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
        selected_agent = selector.select_agent([member1])
        expect(selected_agent).to eq(agent1)
      end
    end
  end
end
