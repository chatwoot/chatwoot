require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Counter do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:label) { create(:label, account: account, title: 'support', show_on_sidebar: true) }
  let(:team) { create(:team, account: account, allow_auto_assign: false) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:store) { Conversations::UnreadCounts::Store }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create(:team_member, user: agent, team: team)
  end

  after do
    store.clear_account!(account.id)
  end

  it 'uses base counts for custom roles with conversation_manage permission' do
    account_user.update!(custom_role: create(:custom_role, account: account, permissions: ['conversation_manage']))
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], assignee: other_agent, team: team)
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)

    result = described_class.new(account: account, user: agent).perform

    expect(result[:inboxes]).to eq(inbox.id.to_s => 2)
    expect(result[:labels]).to eq(label.id.to_s => 2)
    expect(result[:teams]).to eq(team.id.to_s => 2)
    expect(store.assignment_ready?(account.id)).to be(false)
  end

  it 'counts assigned and unassigned conversations for conversation_unassigned_manage permission' do
    account_user.update!(custom_role: create(:custom_role, account: account, permissions: ['conversation_unassigned_manage']))
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], assignee: agent, team: team)
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], assignee: other_agent, team: team)

    result = described_class.new(account: account, user: agent).perform

    expect(result[:inboxes]).to eq(inbox.id.to_s => 2)
    expect(result[:labels]).to eq(label.id.to_s => 2)
    expect(result[:teams]).to eq(team.id.to_s => 2)
    expect(store.assignment_ready?(account.id)).to be(true)
  end

  it 'counts only assigned conversations for conversation_participating_manage permission' do
    account_user.update!(custom_role: create(:custom_role, account: account, permissions: ['conversation_participating_manage']))
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], assignee: agent, team: team)
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)

    result = described_class.new(account: account, user: agent).perform

    expect(result[:inboxes]).to eq(inbox.id.to_s => 1)
    expect(result[:labels]).to eq(label.id.to_s => 1)
    expect(result[:teams]).to eq(team.id.to_s => 1)
    expect(store.assignment_ready?(account.id)).to be(true)
  end

  it 'returns zero for custom roles without conversation permissions' do
    account_user.update!(custom_role: create(:custom_role, account: account, permissions: []))
    create_unread_conversation(account: account, inbox: inbox, labels: [label.title], assignee: agent, team: team)

    result = described_class.new(account: account, user: agent).perform

    expect(result).to eq(inboxes: {}, labels: {}, teams: {})
    expect(store.base_ready?(account.id)).to be(false)
    expect(store.assignment_ready?(account.id)).to be(false)
  end
end
