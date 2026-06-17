class Conversations::UnreadCounts::Counter
  include ::Conversations::UnreadCounts::BuildLockKeys
  include ::Conversations::UnreadCounts::FilterCounter

  MANAGE_ALL_PERMISSION = 'conversation_manage'.freeze
  UNASSIGNED_PERMISSION = 'conversation_unassigned_manage'.freeze
  PARTICIPATING_PERMISSION = 'conversation_participating_manage'.freeze
  BUILD_LOCK_TTL = 15.minutes.to_i
  BUILD_WAIT_TIMEOUT = 30.seconds.to_i
  BUILD_WAIT_INTERVAL = 0.1.seconds

  attr_reader :account, :user

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def perform
    return empty_counts if permission_mode == :none

    ensure_base_cache!
    ensure_assignment_cache! if assignment_mode?
    ensure_filters_cache!

    inbox_counts = unread_inbox_counts
    filter_counts = unread_filter_counts

    {
      all_count: inbox_counts.values.sum,
      inboxes: inbox_counts,
      labels: unread_label_counts,
      teams: unread_team_counts,
      mentions_count: filter_counts[:mentions_count],
      participating_count: filter_counts[:participating_count],
      unattended_count: filter_counts[:unattended_count],
      folders: filter_counts[:folders]
    }
  end

  private

  def ensure_base_cache!
    ensure_cache_ready!(ready: -> { store.base_ready?(account.id) }, lock_key: base_build_lock_key) { builder.build_base! }
  end

  def ensure_assignment_cache!
    ensure_cache_ready!(ready: -> { store.assignment_ready?(account.id) }, lock_key: assignment_build_lock_key) { builder.build_assignment! }
  end

  def ensure_filters_cache!
    ensure_cache_ready!(
      ready: -> { store.filters_ready?(account.id, user.id) },
      lock_key: filters_build_lock_key
    ) { builder.build_filters_for!(user) }
  end

  def ensure_cache_ready!(ready:, lock_key:)
    lock_manager = Redis::LockManager.new

    loop do
      return if ready.call

      lock_acquired = lock_manager.with_lock(lock_key, BUILD_LOCK_TTL) { yield unless ready.call }
      return if ready.call

      wait_for_cache_ready(ready) unless lock_acquired
    end
  end

  def wait_for_cache_ready(ready)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + BUILD_WAIT_TIMEOUT
    sleep BUILD_WAIT_INTERVAL until ready.call || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
  end

  def unread_inbox_counts
    counts_for_grouped_keys(visible_inbox_ids.index_with { |inbox_id| inbox_keys_for_mode(inbox_id) })
  end

  def unread_label_counts
    keys_by_id = Hash.new { |hash, key| hash[key] = [] }
    sidebar_label_ids.each do |label_id|
      visible_inbox_ids.each do |inbox_id|
        keys_by_id[label_id].concat(label_inbox_keys_for_mode(label_id, inbox_id))
      end
    end

    counts_for_grouped_keys(keys_by_id)
  end

  def unread_team_counts
    keys_by_id = Hash.new { |hash, key| hash[key] = [] }
    visible_team_ids.each do |team_id|
      visible_inbox_ids.each do |inbox_id|
        keys_by_id[team_id].concat(team_inbox_keys_for_mode(team_id, inbox_id))
      end
    end

    counts_for_grouped_keys(keys_by_id)
  end

  def inbox_keys_for_mode(inbox_id)
    case permission_mode
    when :base
      [store.inbox_key(account.id, inbox_id)]
    when :unassigned_and_mine
      [store.inbox_unassigned_key(account.id, inbox_id), store.inbox_assignee_key(account.id, inbox_id, user.id)]
    when :mine
      [store.inbox_assignee_key(account.id, inbox_id, user.id)]
    end
  end

  def label_inbox_keys_for_mode(label_id, inbox_id)
    case permission_mode
    when :base
      [store.label_inbox_key(account.id, label_id, inbox_id)]
    when :unassigned_and_mine
      [
        store.label_inbox_unassigned_key(account.id, label_id, inbox_id),
        store.label_inbox_assignee_key(account.id, label_id, inbox_id, user.id)
      ]
    when :mine
      [store.label_inbox_assignee_key(account.id, label_id, inbox_id, user.id)]
    end
  end

  def team_inbox_keys_for_mode(team_id, inbox_id)
    case permission_mode
    when :base
      [store.team_inbox_key(account.id, team_id, inbox_id)]
    when :unassigned_and_mine
      [
        store.team_inbox_unassigned_key(account.id, team_id, inbox_id),
        store.team_inbox_assignee_key(account.id, team_id, inbox_id, user.id)
      ]
    when :mine
      [store.team_inbox_assignee_key(account.id, team_id, inbox_id, user.id)]
    end
  end

  def counts_for_grouped_keys(keys_by_id)
    counts_by_key = store.counts_for_keys(keys_by_id.values.flatten)

    keys_by_id.each_with_object({}) do |(id, keys), result|
      count = keys.sum { |key| counts_by_key[key].to_i }
      result[id.to_s] = count if count.positive?
    end
  end

  def assignment_mode?
    %i[unassigned_and_mine mine].include?(permission_mode)
  end

  def permission_mode
    @permission_mode ||=
      if !custom_role_agent? || permissions.include?(MANAGE_ALL_PERMISSION)
        :base
      elsif permissions.include?(UNASSIGNED_PERMISSION)
        :unassigned_and_mine
      elsif permissions.include?(PARTICIPATING_PERMISSION)
        :mine
      else
        :none
      end
  end

  def custom_role_agent?
    account_user&.agent? && account_user.custom_role_id.present?
  end

  def permissions
    account_user&.permissions || []
  end

  def account_user
    @account_user ||= account.account_users.find_by(user_id: user.id)
  end

  def visible_inbox_ids
    @visible_inbox_ids ||= if account_user&.administrator?
                             account.inboxes.pluck(:id)
                           else
                             user.inboxes.where(account_id: account.id).pluck(:id)
                           end
  end

  def sidebar_label_ids
    @sidebar_label_ids ||= account.labels.where(show_on_sidebar: true).pluck(:id)
  end

  def visible_team_ids
    @visible_team_ids ||= if account_user&.administrator?
                            account.teams.pluck(:id)
                          else
                            user.teams.where(account_id: account.id).pluck(:id)
                          end
  end

  def empty_counts
    { all_count: 0, inboxes: {}, labels: {}, teams: {}, mentions_count: 0, participating_count: 0, unattended_count: 0, folders: {} }
  end

  def store
    ::Conversations::UnreadCounts::Store
  end

  def builder
    @builder ||= ::Conversations::UnreadCounts::Builder.new(account)
  end
end
