require 'rails_helper'

RSpec.describe ChatQueue::Agents::AvailabilityService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:service) { described_class.new(account: account) }

  before do
    allow(OnlineStatusTracker)
      .to receive(:get_available_users)
      .with(account.id)
      .and_return({ agent.id.to_s => 'online' })
  end

  describe '#available?' do
    context 'when agent is nil' do
      it 'returns false' do
        expect(service.available?(nil)).to be false
      end
    end

    context 'when agent is offline' do
      before do
        allow(OnlineStatusTracker)
          .to receive(:get_available_users)
          .with(account.id)
          .and_return({})
      end

      it 'returns false' do
        expect(service.available?(agent)).to be false
      end
    end

    context 'when agent is online' do
      context 'without any limits' do
        it 'returns true' do
          expect(service.available?(agent)).to be true
        end

        it 'returns true even with active conversations' do
          create_list(:conversation, 3, account: account, assignee: agent, status: :open)
          expect(service.available?(agent)).to be true
        end
      end

      context 'with limits set' do
        let(:account_user) { AccountUser.find_by(account: account, user: agent) }

        before do
          account_user.update!(
            active_chat_limit_enabled: true,
            active_chat_limit: 3
          )
        end

        it 'returns true when below limit' do
          create_list(:conversation, 2, account: account, assignee: agent, status: :open)
          expect(service.available?(agent)).to be true
        end

        it 'returns false when at limit' do
          create_list(:conversation, 3, account: account, assignee: agent, status: :open)
          expect(service.available?(agent)).to be false
        end

        it 'returns false when above limit' do
          create_list(:conversation, 4, account: account, assignee: agent, status: :open)
          expect(service.available?(agent)).to be false
        end
      end
    end

    context 'when counting active conversations' do
      before do
        create(:conversation, account: account, assignee: agent, status: :open)
        create(:conversation, account: account, assignee: agent, status: :pending)
        create(:conversation, account: account, assignee: agent, status: :resolved)
        create(:conversation, account: account, assignee: agent, status: :snoozed)

        other_agent = create(:user, account: account)
        create(:conversation, account: account, assignee: other_agent, status: :open)
      end

      it 'counts only non-resolved conversations for this agent' do
        expect(service.send(:active_conversations_count, agent)).to eq(3)
      end
    end

    context 'when testing availability dynamics' do
      let(:account_user) { AccountUser.find_by(account: account, user: agent) }

      before do
        account_user.update!(
          active_chat_limit_enabled: true,
          active_chat_limit: 3
        )
      end

      it 'tracks availability as conversations are added' do
        expect(service.available?(agent)).to be true

        create(:conversation, account: account, assignee: agent, status: :open)
        expect(service.available?(agent)).to be true

        create(:conversation, account: account, assignee: agent, status: :open)
        expect(service.available?(agent)).to be true

        create(:conversation, account: account, assignee: agent, status: :open)
        expect(service.available?(agent)).to be false
      end

      it 'becomes available when conversation is resolved' do
        conversations = create_list(:conversation, 3,
                                    account: account,
                                    assignee: agent,
                                    status: :open)

        expect(service.available?(agent)).to be false

        conversations.first.update!(status: :resolved)
        expect(service.available?(agent)).to be true
      end
    end

    context 'when working with multiple accounts' do
      it 'isolates agents by account' do
        other_account = create(:account)
        other_agent = create(:user, account: other_account)

        allow(OnlineStatusTracker)
          .to receive(:get_available_users)
          .with(other_account.id)
          .and_return({ other_agent.id.to_s => 'online' })

        other_service = described_class.new(account: other_account)

        create_list(:conversation, 5, account: account, assignee: agent, status: :open)

        expect(other_service.available?(other_agent)).to be true
      end
    end
  end
end
