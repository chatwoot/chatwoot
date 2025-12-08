require 'rails_helper'

RSpec.describe ChatQueue::Agents::PermissionsService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent) { create(:user, account: account) }
  let(:other_agent) { create(:user, account: account) }
  let(:service) { described_class.new(account: account) }

  describe '#allowed?' do
    context 'when the agent is a member of the inbox' do
      before do
        create(:inbox_member, inbox: inbox, user: agent)
      end

      it 'returns true' do
        expect(service.allowed?(conversation, agent)).to be true
      end
    end

    context 'when the agent is not a member of the inbox' do
      it 'returns false' do
        expect(service.allowed?(conversation, other_agent)).to be false
      end
    end

    context 'when agent is nil' do
      it 'returns false' do
        expect(service.allowed?(conversation, nil)).to be false
      end
    end

    context 'when conversation is nil' do
      before do
        create(:inbox_member, inbox: inbox, user: agent)
      end

      it 'returns false' do
        expect(service.allowed?(nil, agent)).to be false
      end
    end

    context 'when working with multiple inboxes' do
      let(:inbox2) { create(:inbox, account: account) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox2) }

      before do
        create(:inbox_member, inbox: inbox, user: agent)
        create(:inbox_member, inbox: inbox2, user: other_agent)
      end

      it 'allows agent access to inbox1 conversation' do
        expect(service.allowed?(conversation, agent)).to be true
      end

      it 'denies agent access to inbox2 conversation' do
        expect(service.allowed?(conversation2, agent)).to be false
      end

      it 'allows other_agent access to inbox2 conversation' do
        expect(service.allowed?(conversation2, other_agent)).to be true
      end

      it 'denies other_agent access to inbox1 conversation' do
        expect(service.allowed?(conversation, other_agent)).to be false
      end
    end

    context 'when agent is member of multiple inboxes' do
      let(:inbox2) { create(:inbox, account: account) }
      let(:conversation2) { create(:conversation, account: account, inbox: inbox2) }

      before do
        create(:inbox_member, inbox: inbox, user: agent)
        create(:inbox_member, inbox: inbox2, user: agent)
      end

      it 'allows access to all their inboxes' do
        expect(service.allowed?(conversation, agent)).to be true
        expect(service.allowed?(conversation2, agent)).to be true
      end
    end

    context 'when working with multiple accounts' do
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }
      let(:other_conversation) { create(:conversation, account: other_account, inbox: other_inbox) }
      let(:other_account_agent) { create(:user, account: other_account) }
      let(:other_service) { described_class.new(account: other_account) }

      before do
        create(:inbox_member, inbox: inbox, user: agent)

        create(:inbox_member, inbox: other_inbox, user: other_account_agent)
      end

      it 'allows agent access only within their account' do
        expect(service.allowed?(conversation, agent)).to be true
      end

      it 'denies agent from first account access to second account conversation' do
        expect(other_service.allowed?(other_conversation, agent)).to be false
      end

      it 'allows agent from second account access to their conversation' do
        expect(other_service.allowed?(other_conversation, other_account_agent)).to be true
      end

      it 'denies agent from second account access to first account conversation' do
        expect(service.allowed?(conversation, other_account_agent)).to be false
      end
    end

    context 'when inbox_member exists but for different inbox' do
      let(:inbox2) { create(:inbox, account: account) }

      before do
        create(:inbox_member, inbox: inbox2, user: agent)
      end

      it 'returns false for conversation in inbox that agent is not member of' do
        expect(service.allowed?(conversation, agent)).to be false
      end
    end
  end
end
