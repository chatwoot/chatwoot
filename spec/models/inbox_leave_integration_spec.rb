# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inbox Leave Integration', skip: 'Enterprise feature', type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:account_user1) { create(:account_user, account: account, user: user1) }
  let(:account_user2) { create(:account_user, account: account, user: user2) }
  let(:account_user3) { create(:account_user, account: account, user: user3) }

  before do
    # Create inbox members
    create(:inbox_member, inbox: inbox, user: user1)
    create(:inbox_member, inbox: inbox, user: user2)
    create(:inbox_member, inbox: inbox, user: user3)

    # Set all users as online
    OnlineStatusTracker.set_status(account.id, user1.id, 'online')
    OnlineStatusTracker.set_status(account.id, user2.id, 'online')
    OnlineStatusTracker.set_status(account.id, user3.id, 'online')
  end

  describe '#available_agents' do
    context 'when no one is on leave' do
      it 'returns all online agents' do
        available = inbox.available_agents
        expect(available.map(&:user_id)).to contain_exactly(user1.id, user2.id, user3.id)
      end
    end

    context 'when an agent is on approved leave' do
      before do
        create(:leave, :active, user: user1, account: account)
      end

      it 'excludes the agent on leave' do
        available = inbox.available_agents
        expect(available.map(&:user_id)).to contain_exactly(user2.id, user3.id)
        expect(available.map(&:user_id)).not_to include(user1.id)
      end
    end

    context 'when multiple agents are on leave' do
      before do
        create(:leave, :active, user: user1, account: account)
        create(:leave, :active, user: user2, account: account)
      end

      it 'excludes all agents on leave' do
        available = inbox.available_agents
        expect(available.map(&:user_id)).to contain_exactly(user3.id)
      end
    end

    context 'when an agent has pending leave' do
      before do
        create(:leave, user: user1, account: account, status: 'pending')
      end

      it 'does not exclude agents with pending leave' do
        available = inbox.available_agents
        expect(available.map(&:user_id)).to contain_exactly(user1.id, user2.id, user3.id)
      end
    end

    context 'when an agent has future approved leave' do
      before do
        create(:leave, :future, user: user1, account: account)
      end

      it 'does not exclude agents with future leave' do
        available = inbox.available_agents
        expect(available.map(&:user_id)).to contain_exactly(user1.id, user2.id, user3.id)
      end
    end

    context 'when an agent has past leave' do
      before do
        create(:leave, :past, user: user1, account: account)
      end

      it 'does not exclude agents with past leave' do
        available = inbox.available_agents
        expect(available.map(&:user_id)).to contain_exactly(user1.id, user2.id, user3.id)
      end
    end

    context 'with exclude_on_leave option' do
      before do
        create(:leave, :active, user: user1, account: account)
      end

      it 'excludes agents on leave by default' do
        available = inbox.available_agents
        expect(available.map(&:user_id)).not_to include(user1.id)
      end

      it 'includes agents on leave when exclude_on_leave is false' do
        available = inbox.available_agents(exclude_on_leave: false)
        expect(available.map(&:user_id)).to include(user1.id)
      end
    end
  end
end
