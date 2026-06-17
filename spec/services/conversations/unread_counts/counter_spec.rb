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
    store.clear_all_account!(account.id)
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
    allow(lock_manager).to receive(:with_lock).and_yield.and_return(true)
    allow(lock_manager).to receive(:with_lock).with(lock_key, described_class::BUILD_LOCK_TTL).and_yield.and_return(true)

    create_unread_conversation(account: account, inbox: visible_inbox, labels: [label.title], team: visible_team)

    described_class.new(account: account, user: agent).perform

    expect(lock_manager).to have_received(:with_lock).with(lock_key, described_class::BUILD_LOCK_TTL)
  end

  it 'waits instead of rebuilding when another process owns the base build lock' do
    lock_manager = instance_double(Redis::LockManager, with_lock: false)
    counter = described_class.new(account: account, user: agent)

    allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
    allow(counter).to receive(:wait_for_cache_ready) do
      store.mark_base_ready!(account.id)
      store.mark_filters_ready!(account.id, agent.id)
    end
    expect(Conversations::UnreadCounts::Builder).not_to receive(:new)

    counter.perform

    expect(counter).to have_received(:wait_for_cache_ready)
    expect(store.base_ready?(account.id)).to be(true)
    expect(store.filters_ready?(account.id, agent.id)).to be(true)
  end

  it 'retries when a build finishes without marking the cache ready' do
    builder = instance_double(Conversations::UnreadCounts::Builder)
    attempts = 0
    allow(Conversations::UnreadCounts::Builder).to receive(:new).and_return(builder)
    allow(builder).to receive(:build_base!) do
      attempts += 1
      store.mark_base_ready!(account.id) if attempts == 2
    end
    allow(builder).to receive(:build_filters_for!) { store.mark_filters_ready!(account.id, agent.id) }

    described_class.new(account: account, user: agent).perform

    expect(builder).to have_received(:build_base!).twice
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
      teams: { visible_team.id.to_s => 1 },
      mentions_count: 0,
      participating_count: 0,
      unattended_count: 1,
      folders: {}
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
      teams: { visible_team.id.to_s => 2 },
      mentions_count: 0,
      participating_count: 0,
      unattended_count: 2,
      folders: {}
    )
  end

  it 'does not return zero counts or labels hidden from the sidebar' do
    create_unread_conversation(account: account, inbox: visible_inbox, labels: [hidden_label.title], team: visible_team)

    result = described_class.new(account: account, user: agent).perform

    expect(result).to eq(
      all_count: 1,
      inboxes: { visible_inbox.id.to_s => 1 },
      labels: {},
      teams: { visible_team.id.to_s => 1 },
      mentions_count: 0,
      participating_count: 0,
      unattended_count: 1,
      folders: {}
    )
  end

  it 'returns mention, participating, unattended, and valid folder unread counts for the user' do
    mentioned_conversation = create_unread_conversation(account: account, inbox: visible_inbox)
    participating_conversation = create_unread_conversation(account: account, inbox: visible_inbox)
    resolved_conversation = create_unread_conversation(account: account, inbox: visible_inbox)
    resolved_conversation.update!(status: :resolved)
    valid_folder = create(:custom_filter, account: account, user: agent, filter_type: :conversation, query: filter_query('status', ['resolved']))
    invalid_folder = create(:custom_filter, account: account, user: agent, filter_type: :conversation, query: filter_query('unknown', ['open']))

    create(:mention, account: account, conversation: mentioned_conversation, user: agent)
    create(:conversation_participant, account: account, conversation: participating_conversation, user: agent)

    result = described_class.new(account: account, user: agent).perform

    expect(result[:mentions_count]).to eq(1)
    expect(result[:participating_count]).to eq(1)
    expect(result[:unattended_count]).to eq(2)
    expect(result[:folders]).to eq(valid_folder.id.to_s => 1)
    expect(result[:folders]).not_to have_key(invalid_folder.id.to_s)
    expect(store.filters_ready?(account.id, agent.id)).to be(true)
  end

  def filter_query(attribute_key, values)
    {
      payload: [
        {
          attribute_key: attribute_key,
          filter_operator: 'equal_to',
          values: values,
          query_operator: nil,
          custom_attribute_type: ''
        }
      ]
    }
  end
end
