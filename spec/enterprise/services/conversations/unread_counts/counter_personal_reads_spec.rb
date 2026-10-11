require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Counter do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:role) { create(:custom_role, account: account, permissions: ['conversation_participating_manage']) }

  before do
    account.enable_features!(:individual_conversation_reads)
    account.disable_features!(:unread_count_for_filters)
    create(:inbox_member, inbox: inbox, user: agent)
    agent.account_users.find_by!(account: account).update!(custom_role: role)
  end

  it 'preserves the seller permission boundary while isolating administrator reads' do
    mine = create(:conversation, account: account, inbox: inbox, assignee: agent, read_baseline_at: 1.hour.ago)
    unassigned = create(:conversation, account: account, inbox: inbox, read_baseline_at: 1.hour.ago)
    create(:message, account: account, inbox: inbox, conversation: mine, message_type: :incoming, created_at: 1.minute.ago)
    create(:message, account: account, inbox: inbox, conversation: unassigned, message_type: :incoming, created_at: 1.minute.ago)
    Conversations::ReadStateService.new(conversation: mine, user: admin).mark_read

    expect(described_class.new(account: account, user: agent).perform[:all_count]).to eq(1)
    expect(described_class.new(account: account, user: admin).perform[:all_count]).to eq(1)

    Conversations::ReadStateService.new(conversation: mine, user: agent).mark_read
    expect(described_class.new(account: account, user: agent).perform[:all_count]).to eq(0)
  end
end
