# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::RoundRobinSelector, type: :service do
  before do
    # Mock GlobalConfig to avoid InstallationConfig issues
    allow(GlobalConfig).to receive(:get).and_return({})
    create(:inbox_member, inbox: inbox, user: user1)
    create(:inbox_member, inbox: inbox, user: user2)
    create(:inbox_member, inbox: inbox, user: user3)
  end

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:policy) { create(:assignment_policy, account: account) }
  let(:user1) { create(:user, account: account, availability: :online) }
  let(:user2) { create(:user, account: account, availability: :online) }
  let(:user3) { create(:user, account: account, availability: :offline) }

  describe '#select_agent' do
    let(:selector) { described_class.new(inbox: inbox) }
    let(:round_robin_service) { instance_double(AutoAssignment::InboxRoundRobinService) }
    let(:available_agents) { InboxMember.where(inbox: inbox, user: [user1, user2]) }

    before do
      allow(AutoAssignment::InboxRoundRobinService).to receive(:new).with(inbox: inbox).and_return(round_robin_service)
    end

    context 'when Redis is available' do
      before do
        allow(round_robin_service).to receive(:available_agent).with(allowed_agent_ids: [user1.id.to_s, user2.id.to_s]).and_return(user1.id.to_s)
      end

      it 'returns an online agent' do
        result = selector.select_agent(available_agents)
        expect(result).to eq(user1)
      end

      it 'excludes offline agents' do
        result = selector.select_agent(available_agents)
        expect(result).not_to eq(user3)
      end

      it 'handles no available agent gracefully' do
        allow(round_robin_service).to receive(:available_agent).with(allowed_agent_ids: [user1.id.to_s, user2.id.to_s]).and_return(nil)
        result = selector.select_agent(available_agents)
        expect(result).to be_nil
      end
    end

    context 'when Redis fails' do
      before do
        allow(round_robin_service).to receive(:available_agent).and_raise(Redis::CannotConnectError)
      end

      it 'raises the error' do
        expect { selector.select_agent(available_agents) }.to raise_error(Redis::CannotConnectError)
      end
    end

    context 'with empty available agents' do
      it 'returns nil when no agents are available' do
        result = selector.select_agent(InboxMember.none)
        expect(result).to be_nil
      end
    end

    context 'with different user IDs' do
      it 'correctly finds the inbox member by user_id' do
        allow(round_robin_service).to receive(:available_agent).with(allowed_agent_ids: [user1.id.to_s, user2.id.to_s]).and_return(user2.id.to_s)

        result = selector.select_agent(available_agents)
        expect(result).to eq(user2)
      end
    end
  end

  describe '#add_agent_to_queue' do
    let(:selector) { described_class.new(inbox: inbox) }
    let(:round_robin_service) { instance_double(AutoAssignment::InboxRoundRobinService) }

    before do
      allow(AutoAssignment::InboxRoundRobinService).to receive(:new).with(inbox: inbox).and_return(round_robin_service)
    end

    it 'delegates to round robin service' do
      expect(round_robin_service).to receive(:add_agent_to_queue).with(user1.id)
      selector.add_agent_to_queue(user1.id)
    end
  end

  describe '#remove_agent_from_queue' do
    let(:selector) { described_class.new(inbox: inbox) }
    let(:round_robin_service) { instance_double(AutoAssignment::InboxRoundRobinService) }

    before do
      allow(AutoAssignment::InboxRoundRobinService).to receive(:new).with(inbox: inbox).and_return(round_robin_service)
    end

    it 'delegates to round robin service' do
      expect(round_robin_service).to receive(:remove_agent_from_queue).with(user1.id)
      selector.remove_agent_from_queue(user1.id)
    end
  end

  describe '#reset_queue' do
    let(:selector) { described_class.new(inbox: inbox) }
    let(:round_robin_service) { instance_double(AutoAssignment::InboxRoundRobinService) }

    before do
      allow(AutoAssignment::InboxRoundRobinService).to receive(:new).with(inbox: inbox).and_return(round_robin_service)
    end

    it 'delegates to round robin service' do
      expect(round_robin_service).to receive(:reset_queue)
      selector.reset_queue
    end
  end

  describe 'edge cases' do
    let(:selector) { described_class.new(inbox: inbox) }
    let(:round_robin_service) { instance_double(AutoAssignment::InboxRoundRobinService) }
    let(:available_agents) { InboxMember.where(inbox: inbox, user: [user1, user2]) }

    before do
      allow(AutoAssignment::InboxRoundRobinService).to receive(:new).with(inbox: inbox).and_return(round_robin_service)
    end

    it 'handles invalid user_id from round robin service' do
      allow(round_robin_service).to receive(:available_agent).and_return('invalid_id')

      result = selector.select_agent(available_agents)
      expect(result).to be_nil
    end

    it 'handles user_id not in available agents' do
      other_user = create(:user, account: account)
      allow(round_robin_service).to receive(:available_agent).and_return(other_user.id.to_s)

      result = selector.select_agent(available_agents)
      expect(result).to be_nil
    end
  end
end
