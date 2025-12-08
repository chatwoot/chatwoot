require 'rails_helper'

RSpec.describe ChatQueue::Agents::OnlineAgentsService do
  let(:account) { create(:account) }
  let(:agent1) { create(:user, account: account) }
  let(:agent2) { create(:user, account: account) }
  let(:agent3) { create(:user, account: account) }
  let(:service) { described_class.new(account: account) }

  before do
    allow(OnlineStatusTracker)
      .to receive(:get_available_users)
      .with(account.id)
      .and_return({
                    agent1.id.to_s => 'online',
                    agent2.id.to_s => 'offline',
                    agent3.id.to_s => 'online'
                  })
  end

  describe '#list' do
    context 'when no agents are online' do
      before do
        allow(OnlineStatusTracker)
          .to receive(:get_available_users)
          .with(account.id)
          .and_return({})
      end

      it 'returns empty array' do
        expect(service.list).to eq([])
      end
    end

    context 'when agents are online but have no conversations' do
      it 'returns all online agents' do
        result = service.list
        expect(result).to contain_exactly(agent1.id, agent3.id)
      end

      it 'does not include offline agents' do
        result = service.list
        expect(result).not_to include(agent2.id)
      end
    end

    context 'when sorting by active conversations count' do
      before do
        create_list(:conversation, 3, account: account, assignee: agent1, status: :open)

        create(:conversation, account: account, assignee: agent3, status: :open)
      end

      it 'prioritizes agents with fewer active conversations' do
        result = service.list

        expect(result).to eq([agent3.id, agent1.id])
      end
    end

    context 'when sorting by last closed conversation time' do
      let(:agent4) { create(:user, account: account) }

      before do
        allow(OnlineStatusTracker)
          .to receive(:get_available_users)
          .with(account.id)
          .and_return({
                        agent1.id.to_s => 'online',
                        agent3.id.to_s => 'online',
                        agent4.id.to_s => 'online'
                      })

        create(:conversation, account: account, assignee: agent1, status: :resolved, updated_at: 3.hours.ago)
        create(:conversation, account: account, assignee: agent3, status: :resolved, updated_at: 1.hour.ago)
        create(:conversation, account: account, assignee: agent4, status: :resolved, updated_at: 2.hours.ago)
      end

      it 'prioritizes agents who closed conversations longest ago' do
        result = service.list

        expect(result).to eq([agent1.id, agent4.id, agent3.id])
      end
    end

    context 'when sorting by both criteria (active count + last closed)' do
      let(:agent4) { create(:user, account: account) }
      let(:agent5) { create(:user, account: account) }

      before do
        allow(OnlineStatusTracker)
          .to receive(:get_available_users)
          .with(account.id)
          .and_return({
                        agent1.id.to_s => 'online',
                        agent3.id.to_s => 'online',
                        agent4.id.to_s => 'online',
                        agent5.id.to_s => 'online'
                      })

        create_list(:conversation, 2, account: account, assignee: agent1, status: :open)
        create(:conversation, account: account, assignee: agent1, status: :resolved, updated_at: 5.hours.ago)

        create_list(:conversation, 2, account: account, assignee: agent3, status: :open)
        create(:conversation, account: account, assignee: agent3, status: :resolved, updated_at: 1.hour.ago)

        create(:conversation, account: account, assignee: agent4, status: :open)
        create(:conversation, account: account, assignee: agent4, status: :resolved, updated_at: 2.hours.ago)

        create(:conversation, account: account, assignee: agent5, status: :open)
        create(:conversation, account: account, assignee: agent5, status: :resolved, updated_at: 3.hours.ago)
      end

      it 'sorts first by active count, then by last closed time' do
        result = service.list

        expect(result).to eq([agent5.id, agent4.id, agent1.id, agent3.id])
      end
    end

    context 'when agent has no closed conversations' do
      before do
        create(:conversation, account: account, assignee: agent1, status: :open)
        create(:conversation, account: account, assignee: agent1, status: :resolved, updated_at: 2.hours.ago)

        create(:conversation, account: account, assignee: agent3, status: :open)
      end

      it 'treats agents without closed conversations as having oldest timestamp' do
        result = service.list

        expect(result).to eq([agent3.id, agent1.id])
      end
    end

    context 'when counting different conversation statuses' do
      before do
        create(:conversation, account: account, assignee: agent1, status: :open)
        create(:conversation, account: account, assignee: agent1, status: :pending)
        create(:conversation, account: account, assignee: agent1, status: :snoozed)
        create(:conversation, account: account, assignee: agent1, status: :resolved)

        create_list(:conversation, 3, account: account, assignee: agent3, status: :resolved)
      end

      it 'counts all non-resolved statuses as active' do
        result = service.list

        expect(result).to eq([agent3.id, agent1.id])
      end
    end

    context 'when working with multiple accounts' do
      let(:other_account) { create(:account) }
      let(:other_agent) { create(:user, account: other_account) }
      let(:other_service) { described_class.new(account: other_account) }

      before do
        allow(OnlineStatusTracker)
          .to receive(:get_available_users)
          .with(other_account.id)
          .and_return({ other_agent.id.to_s => 'online' })

        create_list(:conversation, 5, account: account, assignee: agent1, status: :open)
        create_list(:conversation, 2, account: other_account, assignee: other_agent, status: :open)
      end

      it 'isolates agents and conversations by account' do
        expect(service.list).to contain_exactly(agent1.id, agent3.id)

        expect(other_service.list).to eq([other_agent.id])
      end

      it 'does not count conversations from other accounts' do
        stats = other_service.send(:agent_stat_record, other_agent.id)
        expect(stats[:active]).to eq(2)
      end
    end
  end
end
