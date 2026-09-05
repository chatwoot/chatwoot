require 'rails_helper'

RSpec.describe ChatQueue::Agents::SelectorService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:service) { described_class.new(account: account) }

  let(:agent1) { create(:user, account: account) }
  let(:agent2) { create(:user, account: account) }

  let(:online_service) { instance_double(ChatQueue::Agents::OnlineAgentsService) }
  let(:permissions_service) { instance_double(ChatQueue::Agents::PermissionsService) }
  let(:availability_service) { instance_double(ChatQueue::Agents::AvailabilityService) }

  before do
    allow(ChatQueue::Agents::OnlineAgentsService).to receive(:new).with(account: account).and_return(online_service)
    allow(ChatQueue::Agents::PermissionsService).to receive(:new).with(account: account).and_return(permissions_service)
    allow(ChatQueue::Agents::AvailabilityService).to receive(:new).with(account: account).and_return(availability_service)
  end

  describe '#pick_best_agent_for' do
    context 'when no online agents' do
      before do
        allow(online_service).to receive(:list).and_return([])
      end

      it 'returns nil' do
        expect(service.pick_best_agent_for(conversation)).to be_nil
      end
    end

    context 'when online agents exist but none allowed' do
      before do
        allow(online_service).to receive(:list).and_return([agent1.id, agent2.id])

        allow(permissions_service).to receive(:allowed?).with(conversation, agent1).and_return(false)
        allow(permissions_service).to receive(:allowed?).with(conversation, agent2).and_return(false)

        allow(availability_service).to receive(:available?).with(agent1).and_return(false)
        allow(availability_service).to receive(:available?).with(agent2).and_return(false)
      end

      it 'returns nil' do
        expect(service.pick_best_agent_for(conversation)).to be_nil
      end
    end

    context 'when some agents are allowed but none available' do
      before do
        allow(online_service).to receive(:list).and_return([agent1.id, agent2.id])
        allow(permissions_service).to receive(:allowed?).with(conversation, agent1).and_return(true)
        allow(permissions_service).to receive(:allowed?).with(conversation, agent2).and_return(true)
        allow(availability_service).to receive(:available?).with(agent1).and_return(false)
        allow(availability_service).to receive(:available?).with(agent2).and_return(false)
      end

      it 'returns nil' do
        expect(service.pick_best_agent_for(conversation)).to be_nil
      end
    end

    context 'when at least one agent is allowed and available' do
      before do
        allow(online_service).to receive(:list).and_return([agent1.id, agent2.id])
        allow(permissions_service).to receive(:allowed?).with(conversation, agent1).and_return(true)
        allow(availability_service).to receive(:available?).with(agent1).and_return(true)
      end

      it 'returns the first suitable agent' do
        expect(service.pick_best_agent_for(conversation)).to eq(agent1)
      end
    end
  end
end
