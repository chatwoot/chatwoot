require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::FilteredCounter do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:store) { Conversations::UnreadCounts::FilteredCountStore }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    account_user.update!(custom_role: create(:custom_role, account: account, permissions: ['conversation_participating_manage']))
  end

  after do
    redis_keys.each { |key| Redis::Alfred.delete(key) }
  end

  it 'counts participating conversations inside the permission-filtered accessible set' do
    assigned_participating = create_unread_conversation(account: account, inbox: inbox, assignee: agent)
    unassigned_participating = create_unread_conversation(account: account, inbox: inbox)
    assigned_to_other_participating = create_unread_conversation(account: account, inbox: inbox, assignee: other_agent)
    assigned_not_participating = create_unread_conversation(account: account, inbox: inbox, assignee: agent)
    create(:conversation_participant, account: account, conversation: assigned_participating, user: agent)
    create(:conversation_participant, account: account, conversation: unassigned_participating, user: agent)
    create(:conversation_participant, account: account, conversation: assigned_to_other_participating, user: agent)

    result = described_class.new(account: account, user: agent).perform

    expect(result[:participating_count]).to eq(3)
    expect(result[:mentions_count]).to eq(0)
    expect(result[:folders]).to eq({})
    expect(assigned_not_participating.assignee).to eq(agent)
  end

  def redis_keys
    [store.conversation_version_key(account.id)] + built_in_filter_keys + folder_index_keys
  end

  def built_in_filter_keys
    [
      store.built_in_filter_version_key(account.id, agent.id),
      store.built_in_filter_counts_key(account.id, agent.id),
      store.built_in_filter_build_lock_key(account.id, agent.id),
      store.built_in_filter_refresh_throttle_key(account.id, agent.id)
    ]
  end

  def folder_index_keys
    [
      store.folder_index_version_key(account.id, agent.id),
      store.folder_index_key(account.id, agent.id),
      store.folder_index_build_lock_key(account.id, agent.id),
      store.folder_index_refresh_throttle_key(account.id, agent.id)
    ]
  end
end
