# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enterprise::AssignmentV2::CapacityService do
  let(:account) { create(:account) }
  let(:user) { create(:user, accounts: [account]) }
  let(:account_user) { AccountUser.find_by(account: account, user: user) }
  let(:inbox) { create(:inbox, account: account) }
  let(:service) { described_class.new(account_user) }

  describe '#agent_has_capacity?' do
    context 'without capacity policy' do
      it 'returns true' do
        expect(service.agent_has_capacity?).to be true
        expect(service.agent_has_capacity?(inbox)).to be true
      end
    end

    context 'with capacity policy' do
      let(:policy) { Enterprise::AgentCapacityPolicy.create!(account: account, name: 'Test Policy') }

      before do
        account_user.update!(agent_capacity_policy: policy)
      end

      context 'when policy is not applicable' do
        before do
          allow(policy).to receive(:applicable_for_time?).and_return(false)
        end

        it 'returns true' do
          expect(service.agent_has_capacity?).to be true
        end
      end

      context 'when checking inbox capacity' do
        let!(:inbox_limit) do
          Enterprise::InboxCapacityLimit.create!(
            agent_capacity_policy: policy,
            inbox: inbox,
            conversation_limit: 5
          )
        end

        it 'returns true when under limit' do
          create_list(:conversation, 3, account: account, inbox: inbox, assignee: user, status: :open)
          expect(service.agent_has_capacity?(inbox)).to be true
        end

        it 'returns false when at limit' do
          create_list(:conversation, 5, account: account, inbox: inbox, assignee: user, status: :open)
          expect(service.agent_has_capacity?(inbox)).to be false
        end

        it 'checks overall capacity too' do
          policy.update!(exclusion_rules: { 'overall_capacity' => 10 })
          create_list(:conversation, 9, account: account, assignee: user, status: :open)

          # Under inbox limit but close to overall limit
          expect(service.agent_has_capacity?(inbox)).to be true

          # Add one more to hit overall limit
          create(:conversation, account: account, assignee: user, status: :open)
          expect(service.agent_has_capacity?(inbox)).to be false
        end
      end

      context 'when checking overall capacity' do
        before do
          policy.update!(exclusion_rules: { 'overall_capacity' => 10 })
        end

        it 'returns true when under limit' do
          create_list(:conversation, 8, account: account, assignee: user, status: :open)
          expect(service.agent_has_capacity?).to be true
        end

        it 'returns false when at limit' do
          create_list(:conversation, 10, account: account, assignee: user, status: :open)
          expect(service.agent_has_capacity?).to be false
        end
      end
    end
  end

  describe '#agent_capacity_for_inbox' do
    context 'without capacity policy' do
      it 'returns infinity' do
        expect(service.agent_capacity_for_inbox(inbox)).to eq(Float::INFINITY)
      end
    end

    context 'with capacity policy and inbox limit' do
      let(:policy) { Enterprise::AgentCapacityPolicy.create!(account: account, name: 'Test Policy') }
      let!(:inbox_limit) do
        Enterprise::InboxCapacityLimit.create!(
          agent_capacity_policy: policy,
          inbox: inbox,
          conversation_limit: 5
        )
      end

      before do
        account_user.update!(agent_capacity_policy: policy)
      end

      it 'returns remaining capacity' do
        create_list(:conversation, 2, account: account, inbox: inbox, assignee: user, status: :open)
        expect(service.agent_capacity_for_inbox(inbox)).to eq(3)
      end

      it 'returns 0 when at capacity' do
        create_list(:conversation, 5, account: account, inbox: inbox, assignee: user, status: :open)
        expect(service.agent_capacity_for_inbox(inbox)).to eq(0)
      end
    end
  end

  describe '#agent_overall_capacity' do
    context 'without capacity policy' do
      it 'returns infinity' do
        expect(service.agent_overall_capacity).to eq(Float::INFINITY)
      end
    end

    context 'with capacity policy and overall limit' do
      let(:policy) do
        Enterprise::AgentCapacityPolicy.create!(
          account: account,
          name: 'Overall Policy',
          exclusion_rules: { 'overall_capacity' => 10 }
        )
      end

      before do
        account_user.update!(agent_capacity_policy: policy)
      end

      it 'returns remaining capacity' do
        create_list(:conversation, 6, account: account, assignee: user, status: :open)
        expect(service.agent_overall_capacity).to eq(4)
      end

      it 'returns 0 when at capacity' do
        create_list(:conversation, 10, account: account, assignee: user, status: :open)
        expect(service.agent_overall_capacity).to eq(0)
      end
    end
  end

  describe '#current_conversations_count' do
    it 'counts open conversations assigned to user' do
      create_list(:conversation, 3, account: account, assignee: user, status: :open)
      create(:conversation, account: account, assignee: user, status: :resolved)
      create(:conversation, account: account, status: :open)

      expect(service.current_conversations_count).to eq(3)
    end

    it 'counts inbox-specific conversations when inbox provided' do
      create_list(:conversation, 2, account: account, inbox: inbox, assignee: user, status: :open)
      create(:conversation, account: account, assignee: user, status: :open)

      expect(service.current_conversations_count(inbox)).to eq(2)
    end
  end
end
