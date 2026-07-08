class Conversations::UnreadCounts::FilteredCounter
  FEATURE_FLAG = 'unread_count_for_filters'.freeze
  EMPTY_COUNTS = {
    mentions_count: 0,
    participating_count: 0,
    unattended_count: 0,
    folders: {}
  }.freeze

  attr_reader :account, :user, :now

  def self.empty_counts = EMPTY_COUNTS.deep_dup

  def initialize(account:, user:, now: Time.current)
    @account = account
    @user = user
    @now = now
  end

  def perform = instrumentation.observe(:counter_perform, account_id: account.id) { built_in_counts.merge(folders: folder_counts) }

  private

  def built_in_counts = counts_from_built_in_snapshot(built_in_counts_snapshot) || self.class.empty_counts.except(:folders)

  def built_in_counts_snapshot
    versions = version_cache.built_in_filter
    snapshot_or_build(
      scope: :built_in_filter,
      state: store.built_in_filter_counts_state(account_id: account.id, user_id: user.id, versions: versions, now: now),
      lock_key: store.built_in_filter_build_lock_key(account.id, user.id),
      claim_refresh: -> { store.claim_built_in_filter_refresh!(account_id: account.id, user_id: user.id) }
    ) { build_built_in_counts!(versions) }
  end

  def counts_from_built_in_snapshot(snapshot) = snapshot&.fetch(:counts, nil)&.slice(:mentions_count, :participating_count, :unattended_count)

  def folder_counts
    folder_index = folder_index_snapshot
    return {} if folder_index.blank?

    @inline_filter_builds = 0
    folder_index[:filter_ids].each_with_object({}) do |filter_id, counts|
      count = filter_count(filter_id)
      counts[filter_id.to_s] = count if count.to_i.positive?
    end
  end

  def folder_index_snapshot
    versions = version_cache.folder_index
    snapshot_or_build(
      scope: :folder_index,
      state: store.folder_index_state(account_id: account.id, user_id: user.id, versions: versions, now: now),
      lock_key: store.folder_index_build_lock_key(account.id, user.id),
      claim_refresh: -> { store.claim_folder_index_refresh!(account_id: account.id, user_id: user.id) }
    ) { build_folder_index!(versions) }
  end

  def filter_count(filter_id)
    versions = version_cache.filter(filter_id)
    snapshot = snapshot_or_build(
      scope: :filter,
      state: store.filter_count_state(account_id: account.id, filter_id: filter_id, owner_user_id: user.id, versions: versions, now: now),
      lock_key: store.filter_build_lock_key(account.id, filter_id),
      claim_refresh: -> { filter_build_available? && store.claim_filter_refresh!(account_id: account.id, filter_id: filter_id) }
    ) do
      track_filter_build!
      build_filter_count!(filter_id, versions)
    end

    snapshot&.fetch(:count, nil)
  end

  def snapshot_or_build(scope:, state:, lock_key:, claim_refresh:, &)
    snapshot_resolver.resolve(scope: scope, state: state, lock_key: lock_key, claim_refresh: claim_refresh, &)
  end

  def filter_build_available? = @inline_filter_builds.to_i < Conversations::UnreadCounts::MAX_INLINE_FILTER_BUILDS

  def track_filter_build! = @inline_filter_builds = @inline_filter_builds.to_i + 1

  def build_built_in_counts!(versions)
    store.write_built_in_filter_counts!(**built_in_count_snapshot_payload(versions))
    store.built_in_filter_counts(account_id: account.id, user_id: user.id)
  end

  def built_in_count_snapshot_payload(versions)
    {
      account_id: account.id,
      user_id: user.id,
      counts: built_in_counts_from_database,
      account_version: versions.fetch(:account_version),
      built_in_filter_version: versions.fetch(:built_in_filter_version),
      built_at: now
    }
  end

  def built_in_counts_from_database
    {
      mentions_count: count_relation(mentioned_unread_conversations),
      participating_count: count_relation(participating_unread_conversations),
      unattended_count: count_relation(unread_open_accessible_conversations.unattended)
    }
  end

  def mentioned_unread_conversations
    unread_open_accessible_conversations
      .joins(:mentions)
      .where(mentions: { account_id: account.id, user_id: user.id })
  end

  def participating_unread_conversations
    unread_open_accessible_conversations
      .joins(:conversation_participants)
      .where(conversation_participants: { user_id: user.id })
  end

  def build_folder_index!(versions)
    store.write_folder_index!(
      account_id: account.id,
      user_id: user.id,
      filter_ids: folder_filter_ids_from_database,
      folder_index_version: versions.fetch(:folder_index_version),
      built_at: now
    )
    store.folder_index(account_id: account.id, user_id: user.id)
  end

  def folder_filter_ids_from_database = account.custom_filters.where(user_id: user.id, filter_type: :conversation).pluck(:id)

  def build_filter_count!(filter_id, versions)
    custom_filter = account.custom_filters.find_by(id: filter_id, user_id: user.id, filter_type: :conversation)
    return delete_filter_count!(filter_id) if custom_filter.blank?

    count = filter_query_count(custom_filter)
    return delete_filter_count!(filter_id) if count.nil?

    write_filter_count!(filter_id, count, versions)
    store.filter_count(account_id: account.id, filter_id: filter_id)
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue
    delete_filter_count!(filter_id)
  end

  def filter_query_count(custom_filter)
    ::Conversations::UnreadCounts::FilterQueryCounter.new(
      account: account,
      user: user,
      query: custom_filter.query
    ).perform
  end

  def write_filter_count!(filter_id, count, versions)
    store.write_filter_count!(
      account_id: account.id,
      filter_id: filter_id,
      user_id: user.id,
      count: count,
      account_version: versions.fetch(:account_version),
      filter_version: versions.fetch(:filter_version),
      owner_built_in_filter_version: versions.fetch(:owner_built_in_filter_version),
      built_at: now
    )
  end

  def version_cache = @version_cache ||= ::Conversations::UnreadCounts::FilteredCountVersionCache.new(account: account, user: user, store: store)

  def delete_filter_count!(filter_id) = store.delete_filter_count!(account_id: account.id, filter_id: filter_id).then { nil }

  def unread_open_accessible_conversations
    @unread_open_accessible_conversations ||= Conversations::PermissionFilterService.new(
      unread_conversations.open,
      user,
      account
    ).perform
  end

  def unread_conversations
    account.conversations
           .joins(:messages)
           .merge(Message.incoming.reorder(nil))
           .where(messages: { account_id: account.id })
           .where(unread_since_last_seen_condition)
           .distinct
  end

  def unread_since_last_seen_condition
    conversations = Conversation.arel_table
    messages = Message.arel_table

    conversations[:agent_last_seen_at].eq(nil).or(messages[:created_at].gt(conversations[:agent_last_seen_at]))
  end

  def count_relation(relation) = relation.unscope(:order).count

  def lock_manager = @lock_manager ||= Redis::LockManager.new

  def snapshot_resolver
    @snapshot_resolver ||= ::Conversations::UnreadCounts::FilteredCountSnapshotResolver.new(
      account: account,
      now: now,
      store: store,
      lock_manager: lock_manager
    )
  end

  def store
    ::Conversations::UnreadCounts::FilteredCountStore
  end

  def instrumentation
    ::Conversations::UnreadCounts::FilteredCountInstrumentation
  end
end
