require 'rails_helper'

describe Conversations::AssignmentRulesService do
  subject(:validate) { described_class.new(account: account, assignee: agent, conversations: conversations).validate! }

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversations) { [create(:conversation, account: account, status: :open)] }

  before do
    agent.account_users.find_by(account: account).update!(max_open_conversations: 2)
  end

  it 'allows assignments when the agent has no limit' do
    agent.account_users.find_by(account: account).update!(max_open_conversations: nil)
    create_list(:conversation, 3, account: account, assignee: agent, status: :open)

    expect { validate }.not_to raise_error
  end

  it 'allows reaching the limit exactly' do
    create(:conversation, account: account, assignee: agent, status: :open)

    expect { validate }.not_to raise_error
  end

  it 'rejects assignments that go over the limit' do
    create_list(:conversation, 2, account: account, assignee: agent, status: :open)

    expect { validate }.to raise_error(
      CustomExceptions::ConversationAssignmentNotAllowed,
      "#{agent.available_name} has reached the limit of 2 open assigned conversations"
    )
  end

  context 'when assigning several conversations' do
    let(:conversations) { create_list(:conversation, 2, account: account, status: :open) }

    it 'counts every conversation being assigned' do
      create(:conversation, account: account, assignee: agent, status: :open)

      expect { validate }.to raise_error(CustomExceptions::ConversationAssignmentNotAllowed)
    end
  end

  context 'when some conversations are not open' do
    let(:conversations) do
      [create(:conversation, account: account, status: :open), create(:conversation, account: account, status: :pending)]
    end

    it 'only counts open conversations' do
      create(:conversation, account: account, assignee: agent, status: :resolved)
      create(:conversation, account: account, assignee: agent, status: :pending)
      create(:conversation, account: account, assignee: agent, status: :open)

      expect { validate }.not_to raise_error
    end
  end

  context 'when the conversation is already assigned to the agent' do
    let(:conversations) { [create(:conversation, account: account, assignee: agent, status: :open)] }

    it 'does not count it twice' do
      create(:conversation, account: account, assignee: agent, status: :open)

      expect { validate }.not_to raise_error
    end
  end
end
