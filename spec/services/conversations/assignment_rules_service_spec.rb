require 'rails_helper'

describe Conversations::AssignmentRulesService do
  subject(:service) { described_class.new(account: account, assignee: agent) }

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, status: :open) }

  before do
    agent.account_users.find_by(account: account).update!(max_open_conversations: 2)
  end

  describe '#enforce!' do
    it 'returns the block result when the agent stays within the limit' do
      create(:conversation, account: account, assignee: agent, status: :open)

      expect(service.enforce! { conversation.update!(assignee: agent) && :assigned }).to eq(:assigned)
      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'rolls back writes that take the agent over the limit' do
      create_list(:conversation, 2, account: account, assignee: agent, status: :open)

      expect { service.enforce! { conversation.update!(assignee: agent) } }.to raise_error(
        CustomExceptions::ConversationAssignmentNotAllowed,
        "#{agent.available_name} has reached the limit of 2 open assigned conversations"
      )
      expect(conversation.reload.assignee).to be_nil
    end

    it 'counts conversations that become open in the block' do
      create_list(:conversation, 2, account: account, assignee: agent, status: :open)
      resolved_conversation = create(:conversation, account: account, assignee: agent, status: :resolved)

      expect { service.enforce! { resolved_conversation.update!(status: :open) } }.to raise_error(CustomExceptions::ConversationAssignmentNotAllowed)
      expect(resolved_conversation.reload).to be_resolved
    end

    it 'allows writes that do not add open conversations when the agent is already over the limit' do
      create_list(:conversation, 3, account: account, assignee: agent, status: :open)
      pending_conversation = create(:conversation, account: account, status: :pending)

      expect { service.enforce! { pending_conversation.update!(assignee: agent) } }.not_to raise_error
    end

    it 'skips the check when the agent has no limit' do
      agent.account_users.find_by(account: account).update!(max_open_conversations: nil)
      create_list(:conversation, 3, account: account, assignee: agent, status: :open)

      expect { service.enforce! { conversation.update!(assignee: agent) } }.not_to raise_error
    end

    it 'skips the check without an assignee' do
      expect(described_class.new(account: account, assignee: nil).enforce! { :done }).to eq(:done)
    end
  end

  describe '#validate!' do
    it 'allows reaching the limit exactly' do
      create(:conversation, account: account, assignee: agent, status: :open)

      expect { service.validate!([conversation]) }.not_to raise_error
    end

    it 'counts every open conversation being assigned' do
      create(:conversation, account: account, assignee: agent, status: :open)

      expect { service.validate!([conversation, create(:conversation, account: account, status: :open)]) }
        .to raise_error(CustomExceptions::ConversationAssignmentNotAllowed)
    end

    it 'ignores conversations that stay closed or already belong to the agent' do
      create(:conversation, account: account, assignee: agent, status: :open)
      own_conversation = create(:conversation, account: account, assignee: agent, status: :open)
      resolved_conversation = create(:conversation, account: account, status: :resolved)

      expect { service.validate!([own_conversation, resolved_conversation]) }.not_to raise_error
    end

    it 'uses the requested status instead of the current one' do
      create_list(:conversation, 2, account: account, assignee: agent, status: :open)
      resolved_conversation = create(:conversation, account: account, status: :resolved)

      expect { service.validate!([resolved_conversation], status: 'open') }.to raise_error(CustomExceptions::ConversationAssignmentNotAllowed)
    end
  end
end
