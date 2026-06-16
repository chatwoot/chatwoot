require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::Builder do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:label) { create(:label, account: account, title: 'urgent', show_on_sidebar: true) }
  let(:assignee) { create(:user, account: account, role: :agent) }
  let(:team) { create(:team, account: account, allow_auto_assign: false) }
  let(:store) { Conversations::UnreadCounts::Store }

  after do
    store.clear_all_account!(account.id)
  end

  describe '#build_base!' do
    it 'stores unread open conversations by inbox and label inbox' do
      unread_conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)
      create_read_conversation
      create_resolved_unread_conversation

      described_class.new(account).build_base!

      expect(store.base_ready?(account.id)).to be(true)
      expect(redis_set_members(store.inbox_key(account.id, inbox.id))).to contain_exactly(unread_conversation.id.to_s)
      expect(redis_set_members(store.label_inbox_key(account.id, label.id, inbox.id))).to contain_exactly(unread_conversation.id.to_s)
      expect(redis_set_members(store.team_inbox_key(account.id, team.id, inbox.id))).to contain_exactly(unread_conversation.id.to_s)
    end

    it 'clears assignment-aware cache data before rebuilding base data' do
      assigned_conversation = create_unread_conversation(
        account: account,
        inbox: inbox,
        labels: [label.title],
        assignee: assignee,
        team: team
      )

      described_class.new(account).build_assignment!
      described_class.new(account).build_base!

      expect(store.assignment_ready?(account.id)).to be(false)
      expect(redis_set_members(store.inbox_assignee_key(account.id, inbox.id, assignee.id))).to be_empty
      expect(redis_set_members(store.inbox_key(account.id, inbox.id))).to contain_exactly(assigned_conversation.id.to_s)
    end
  end

  describe '#build_assignment!' do
    it 'stores unread open conversations by unassigned and assignee dimensions' do
      assigned_conversation = create_unread_conversation(
        account: account,
        inbox: inbox,
        labels: [label.title],
        assignee: assignee,
        team: team
      )
      unassigned_conversation = create_unread_conversation(account: account, inbox: inbox, labels: [label.title], team: team)

      described_class.new(account).build_assignment!

      expect(store.assignment_ready?(account.id)).to be(true)
      expect(redis_set_members(store.inbox_assignee_key(account.id, inbox.id, assignee.id))).to contain_exactly(assigned_conversation.id.to_s)
      expect(redis_set_members(store.label_inbox_assignee_key(account.id, label.id, inbox.id, assignee.id))).to contain_exactly(
        assigned_conversation.id.to_s
      )
      expect(redis_set_members(store.team_inbox_assignee_key(account.id, team.id, inbox.id, assignee.id))).to contain_exactly(
        assigned_conversation.id.to_s
      )
      expect(redis_set_members(store.inbox_unassigned_key(account.id, inbox.id))).to contain_exactly(unassigned_conversation.id.to_s)
      expect(redis_set_members(store.label_inbox_unassigned_key(account.id, label.id, inbox.id))).to contain_exactly(
        unassigned_conversation.id.to_s
      )
      expect(redis_set_members(store.team_inbox_unassigned_key(account.id, team.id, inbox.id))).to contain_exactly(
        unassigned_conversation.id.to_s
      )
    end
  end

  describe '#build_filters_for!' do
    before do
      create(:inbox_member, user: assignee, inbox: inbox)
    end

    it 'stores unread open conversations by mentions and participating dimensions' do
      mentioned_conversation = create_unread_conversation(account: account, inbox: inbox)
      participating_conversation = create_unread_conversation(account: account, inbox: inbox)
      resolved_mentioned_conversation = create_unread_conversation(account: account, inbox: inbox)
      inaccessible_conversation = create_unread_conversation(account: account, inbox: create(:inbox, account: account))
      resolved_mentioned_conversation.update!(status: :resolved)

      create(:mention, account: account, conversation: mentioned_conversation, user: assignee)
      create(:mention, account: account, conversation: resolved_mentioned_conversation, user: assignee)
      create(:mention, account: account, conversation: inaccessible_conversation, user: assignee)
      create(:conversation_participant, account: account, conversation: participating_conversation, user: assignee)

      described_class.new(account).build_filters_for!(assignee)

      expect(store.filters_ready?(account.id, assignee.id)).to be(true)
      expect(redis_set_members(store.user_mentions_key(account.id, assignee.id))).to contain_exactly(mentioned_conversation.id.to_s)
      expect(redis_set_members(store.user_participating_key(account.id, assignee.id))).to contain_exactly(participating_conversation.id.to_s)
    end

    it 'excludes participating conversations that are no longer visible to the user' do
      participating_conversation = create_unread_conversation(account: account, inbox: inbox)
      create(:conversation_participant, account: account, conversation: participating_conversation, user: assignee)
      InboxMember.find_by!(user: assignee, inbox: inbox).destroy!

      described_class.new(account).build_filters_for!(assignee)

      expect(redis_set_members(store.user_participating_key(account.id, assignee.id))).to be_empty
    end

    it 'stores visible unread open unattended conversations' do
      no_first_reply_conversation = create_unread_conversation(account: account, inbox: inbox)
      waiting_conversation = create_unread_conversation(account: account, inbox: inbox)
      attended_conversation = create_unread_conversation(account: account, inbox: inbox)
      inaccessible_conversation = create_unread_conversation(account: account, inbox: create(:inbox, account: account))
      resolved_conversation = create_unread_conversation(account: account, inbox: inbox)
      create_read_conversation

      waiting_conversation.update!(first_reply_created_at: 5.minutes.ago)
      attended_conversation.update!(first_reply_created_at: 5.minutes.ago, waiting_since: nil)
      inaccessible_conversation.update!(first_reply_created_at: nil)
      resolved_conversation.update!(status: :resolved)

      described_class.new(account).build_filters_for!(assignee)

      expect(redis_set_members(store.user_unattended_key(account.id, assignee.id))).to contain_exactly(
        no_first_reply_conversation.id.to_s,
        waiting_conversation.id.to_s
      )
    end

    it 'stores folder memberships using the saved filter status conditions' do
      resolved_conversation = create_unread_conversation(account: account, inbox: inbox)
      resolved_conversation.update!(status: :resolved)
      create_unread_conversation(account: account, inbox: inbox, assignee: assignee)
      custom_filter = create(
        :custom_filter, account: account, user: assignee, filter_type: :conversation, query: filter_query('status', ['resolved'])
      )

      described_class.new(account).build_filters_for!(assignee)

      expect(redis_set_members(store.user_folder_key(account.id, assignee.id, custom_filter.id))).to contain_exactly(resolved_conversation.id.to_s)
    end

    it 'loads folder filters after taking the invalidation version snapshot' do
      create_unread_conversation(account: account, inbox: inbox)
      resolved_conversation = create_unread_conversation(account: account, inbox: inbox)
      resolved_conversation.update!(status: :resolved)
      custom_filter = create(
        :custom_filter, account: account, user: assignee, filter_type: :conversation, query: filter_query('status', ['open'])
      )
      notifier = instance_double(Conversations::UnreadCounts::UserFilterNotifier, perform: true)
      allow(Conversations::UnreadCounts::UserFilterNotifier).to receive(:new).and_return(notifier)
      filter_updated = false
      allow(store).to receive(:filter_version_snapshot).and_wrap_original do |method, *args|
        method.call(*args).tap do
          next if filter_updated

          filter_updated = true
          custom_filter.update!(query: filter_query('status', ['resolved']))
        end
      end

      described_class.new(account).build_filters_for!(assignee)

      expect(redis_set_members(store.user_folder_key(account.id, assignee.id, custom_filter.id))).to contain_exactly(resolved_conversation.id.to_s)
    end

    it 'expires relative-date folder caches at the next date boundary' do
      create(
        :custom_filter,
        account: account,
        user: assignee,
        filter_type: :conversation,
        query: filter_query('created_at', [7], filter_operator: 'days_before')
      )
      allow(store).to receive(:mark_filters_ready_if_current!).and_call_original
      expected_ttl = nil

      travel_to Time.zone.local(2026, 1, 1, 9, 30, 0) do
        expected_ttl = (Time.zone.tomorrow.beginning_of_day - Time.current).ceil
        described_class.new(account).build_filters_for!(assignee)
      end

      expect(store).to have_received(:mark_filters_ready_if_current!).with(
        account.id,
        assignee.id,
        version_snapshot: kind_of(Hash),
        expires_in: expected_ttl
      )
    end

    it 'does not mark filters ready when user filters are invalidated during the build' do
      conversation = create_unread_conversation(account: account, inbox: inbox)
      create(:mention, account: account, conversation: conversation, user: assignee)
      clear_user_filters_after_membership_write

      described_class.new(account).build_filters_for!(assignee)

      expect(store.filters_ready?(account.id, assignee.id)).to be(false)
      expect(redis_set_members(store.user_mentions_key(account.id, assignee.id))).to be_empty
    end

    it 'does not mark filters ready when account filters are invalidated during the build' do
      conversation = create_unread_conversation(account: account, inbox: inbox)
      create(:mention, account: account, conversation: conversation, user: assignee)
      clear_filter_caches_after_membership_write

      described_class.new(account).build_filters_for!(assignee)

      expect(store.filters_ready?(account.id, assignee.id)).to be(false)
      expect(redis_set_members(store.user_mentions_key(account.id, assignee.id))).to be_empty
    end

    it 'skips invalid folder filters and still marks the user filter cache ready' do
      create_unread_conversation(account: account, inbox: inbox)
      invalid_filter = create(
        :custom_filter, account: account, user: assignee, filter_type: :conversation, query: filter_query('missing_attribute', ['open'])
      )

      described_class.new(account).build_filters_for!(assignee)

      expect(store.filters_ready?(account.id, assignee.id)).to be(true)
      expect(redis_set_members(store.user_folder_key(account.id, assignee.id, invalid_filter.id))).to be_empty
    end

    it 'skips folder filters that fail when the SQL query is executed' do
      conversation = create_unread_conversation(account: account, inbox: inbox)
      invalid_filter = create(
        :custom_filter,
        account: account,
        user: assignee,
        filter_type: :conversation,
        query: filter_query('display_id', [conversation.display_id.to_s], filter_operator: 'contains')
      )

      expect { described_class.new(account).build_filters_for!(assignee) }.not_to raise_error

      expect(store.filters_ready?(account.id, assignee.id)).to be(true)
      expect(redis_set_members(store.user_folder_key(account.id, assignee.id, invalid_filter.id))).to be_empty
    end
  end

  def create_read_conversation
    conversation = create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.minute.from_now)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
    conversation
  end

  def create_resolved_unread_conversation
    conversation = create_unread_conversation(account: account, inbox: inbox)
    conversation.update!(status: :resolved)
    conversation
  end

  def redis_set_members(key)
    Redis::Alfred.pipelined { |pipeline| pipeline.smembers(key) }.first
  end

  def clear_user_filters_after_membership_write
    allow(store).to receive(:add_filter_memberships).and_wrap_original do |method, *args, **kwargs|
      method.call(*args, **kwargs)
      store.clear_user_filters!(account.id, assignee.id)
    end
  end

  def clear_filter_caches_after_membership_write
    allow(store).to receive(:add_filter_memberships).and_wrap_original do |method, *args, **kwargs|
      method.call(*args, **kwargs)
      store.clear_filter_caches!(account.id)
    end
  end

  def filter_query(attribute_key, values, filter_operator: 'equal_to')
    {
      payload: [
        {
          attribute_key: attribute_key,
          filter_operator: filter_operator,
          values: values,
          query_operator: nil,
          custom_attribute_type: ''
        }
      ]
    }
  end
end
