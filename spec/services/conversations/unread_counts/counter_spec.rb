require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Counter do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:visible_inbox) { create(:inbox, account: account) }
  let(:hidden_inbox) { create(:inbox, account: account) }
  let(:label) { create(:label, account: account, title: 'billing', show_on_sidebar: true) }
  let(:hidden_label) { create(:label, account: account, title: 'internal', show_on_sidebar: false) }
  let(:visible_team) { create(:team, account: account, allow_auto_assign: false) }
  let(:store) { Conversations::UnreadCounts::Store }

  before do
    create(:inbox_member, user: agent, inbox: visible_inbox)
    create(:team_member, user: agent, team: visible_team)
  end

  after do
    store.clear_account!(account.id)
  end

  it 'builds the base cache on demand' do
    create_unread_conversation(account: account, inbox: visible_inbox, labels: [label.title], team: visible_team)

    described_class.new(account: account, user: agent).perform

    expect(store.base_ready?(account.id)).to be(true)
  end

  it 'uses a Redis lock while building the base cache on demand' do
    lock_key = "UNREAD_CONVERSATIONS::V1::ACCOUNT::#{account.id}::BUILD_LOCK::BASE"
    lock_manager = instance_double(Redis::LockManager)
    allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
    allow(lock_manager).to receive(:with_lock).with(lock_key, described_class::BUILD_LOCK_TTL).and_yield.and_return(true)

    create_unread_conversation(account: account, inbox: visible_inbox, labels: [label.title], team: visible_team)

    described_class.new(account: account, user: agent).perform

    expect(lock_manager).to have_received(:with_lock).with(lock_key, described_class::BUILD_LOCK_TTL)
  end

  it 'waits instead of rebuilding when another process owns the base build lock' do
    lock_manager = instance_double(Redis::LockManager, with_lock: false)
    counter = described_class.new(account: account, user: agent)

    allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
    allow(counter).to receive(:wait_for_cache_ready) { store.mark_base_ready!(account.id) }
    expect(Conversations::UnreadCounts::Builder).not_to receive(:new)

    counter.perform

    expect(counter).to have_received(:wait_for_cache_ready)
    expect(store.base_ready?(account.id)).to be(true)
  end

  it 'counts unread conversations only across inboxes visible to a normal agent' do
    create_unread_conversation(account: account, inbox: visible_inbox, labels: [label.title], team: visible_team)
    create_unread_conversation(account: account, inbox: hidden_inbox, labels: [label.title], team: visible_team)

    result = described_class.new(account: account, user: agent).perform

    expect(result).to eq(
      all_count: 1,
      inboxes: { visible_inbox.id.to_s => 1 },
      labels: { label.id.to_s => 1 },
      teams: { visible_team.id.to_s => 1 }
    )
  end

  it 'counts unread conversations across all account inboxes for admins' do
    create_unread_conversation(account: account, inbox: visible_inbox, labels: [label.title], team: visible_team)
    create_unread_conversation(account: account, inbox: hidden_inbox, labels: [label.title], team: visible_team)

    result = described_class.new(account: account, user: admin).perform

    expect(result).to eq(
      all_count: 2,
      inboxes: { visible_inbox.id.to_s => 1, hidden_inbox.id.to_s => 1 },
      labels: { label.id.to_s => 2 },
      teams: { visible_team.id.to_s => 2 }
    )
  end

  it 'does not return zero counts or labels hidden from the sidebar' do
    create_unread_conversation(account: account, inbox: visible_inbox, labels: [hidden_label.title], team: visible_team)

    result = described_class.new(account: account, user: agent).perform

    expect(result).to eq(
      all_count: 1,
      inboxes: { visible_inbox.id.to_s => 1 },
      labels: {},
      teams: { visible_team.id.to_s => 1 }
    )
  end
end
