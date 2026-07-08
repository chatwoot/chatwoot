class Conversations::UnreadCounts::FilteredCountStore
  extend Conversations::UnreadCounts::FilteredCountStoreKeys

  SnapshotResult = Struct.new(:status, :payload, keyword_init: true) do
    def fresh? = status == :fresh
    def stale? = status == :stale
    def expired? = status == :expired
    def missing? = status == :missing
  end

  VERSION_KEY_METHODS = {
    conversation: :conversation_version_key,
    built_in_filter: :built_in_filter_version_key,
    folder_index: :folder_index_version_key,
    filter: :filter_version_key
  }.freeze
  REFRESH_THROTTLE_KEY_METHODS = {
    built_in_filter: :built_in_filter_refresh_throttle_key,
    folder_index: :folder_index_refresh_throttle_key,
    filter: :filter_refresh_throttle_key
  }.freeze
  private_constant :VERSION_KEY_METHODS, :REFRESH_THROTTLE_KEY_METHODS

  class << self
    def conversation_version(account_id) = current_version_for(:conversation, account_id)
    def built_in_filter_version(account_id:, user_id:) = current_version_for(:built_in_filter, account_id, user_id)
    def folder_index_version(account_id:, user_id:) = current_version_for(:folder_index, account_id, user_id)
    def filter_version(account_id:, filter_id:) = current_version_for(:filter, account_id, filter_id)

    def bump_conversation_version!(account_id) = bump_version_for!(:conversation, account_id)
    def bump_built_in_filter_version!(account_id:, user_id:) = bump_version_for!(:built_in_filter, account_id, user_id)
    def bump_folder_index_version!(account_id:, user_id:) = bump_version_for!(:folder_index, account_id, user_id)
    def bump_filter_version!(account_id:, filter_id:) = bump_version_for!(:filter, account_id, filter_id)

    # Keep version dimensions explicit so callers cannot write a snapshot without the freshness contract it depends on.
    def write_built_in_filter_counts!(account_id:, user_id:, counts:, account_version:, built_in_filter_version:, built_at: Time.current, meta: {}) # rubocop:disable Metrics/ParameterLists
      payload = snapshot_payload(built_at).merge(
        account_version: account_version,
        built_in_filter_version: built_in_filter_version,
        user_id: user_id,
        counts: counts,
        meta: meta
      )
      write_snapshot(built_in_filter_counts_key(account_id, user_id), payload)
    end

    def built_in_filter_counts(account_id:, user_id:)
      read_snapshot(built_in_filter_counts_key(account_id, user_id))
    end

    def built_in_filter_counts_state(account_id:, user_id:, versions: nil, now: Time.current)
      snapshot_state(
        built_in_filter_counts(account_id: account_id, user_id: user_id),
        versions: versions || {
          account_version: conversation_version(account_id),
          built_in_filter_version: built_in_filter_version(account_id: account_id, user_id: user_id)
        },
        now: now
      )
    end

    def write_folder_index!(account_id:, user_id:, filter_ids:, folder_index_version:, built_at: Time.current)
      payload = snapshot_payload(built_at).merge(
        folder_index_version: folder_index_version,
        user_id: user_id,
        filter_ids: Array(filter_ids).map(&:to_i)
      )
      write_snapshot(folder_index_key(account_id, user_id), payload)
    end

    def folder_index(account_id:, user_id:)
      read_snapshot(folder_index_key(account_id, user_id))
    end

    def folder_index_state(account_id:, user_id:, versions: nil, now: Time.current)
      snapshot_state(
        folder_index(account_id: account_id, user_id: user_id),
        versions: versions || { folder_index_version: folder_index_version(account_id: account_id, user_id: user_id) },
        now: now
      )
    end

    # Saved folder snapshots depend on account, filter, and owner visibility versions; keep all three visible at the callsite.
    def write_filter_count!(account_id:, filter_id:, user_id:, count:, account_version:, filter_version:, owner_built_in_filter_version:, # rubocop:disable Metrics/ParameterLists
                            built_at: Time.current, meta: {})
      payload = snapshot_payload(built_at).merge(
        account_version: account_version,
        filter_version: filter_version,
        owner_built_in_filter_version: owner_built_in_filter_version,
        filter_id: filter_id,
        user_id: user_id,
        count: count,
        meta: meta
      )
      write_snapshot(filter_count_key(account_id, filter_id), payload)
    end

    def filter_count(account_id:, filter_id:)
      read_snapshot(filter_count_key(account_id, filter_id))
    end

    def filter_count_state(account_id:, filter_id:, owner_user_id: nil, versions: nil, now: Time.current)
      snapshot = filter_count(account_id: account_id, filter_id: filter_id)
      return SnapshotResult.new(status: :missing, payload: nil) if snapshot.blank?

      owner_user_id ||= snapshot[:user_id]
      snapshot_state(
        snapshot,
        versions: versions || {
          account_version: conversation_version(account_id),
          filter_version: filter_version(account_id: account_id, filter_id: filter_id),
          owner_built_in_filter_version: built_in_filter_version(account_id: account_id, user_id: owner_user_id)
        },
        now: now
      )
    end

    def refresh_due?(snapshot, now: Time.current)
      return true if snapshot.blank?

      refresh_after = parse_time(snapshot[:refresh_after])
      refresh_after.blank? || now >= refresh_after
    end

    def claim_built_in_filter_refresh!(account_id:, user_id:) = claim_refresh_for!(:built_in_filter, account_id, user_id)
    def claim_folder_index_refresh!(account_id:, user_id:) = claim_refresh_for!(:folder_index, account_id, user_id)
    def claim_filter_refresh!(account_id:, filter_id:) = claim_refresh_for!(:filter, account_id, filter_id)

    def delete_filter_count!(account_id:, filter_id:)
      Redis::Alfred.delete(filter_count_key(account_id, filter_id))
    end

    private

    # Keep the public API domain-specific while centralizing direct Redis version/throttle operations.
    def current_version_for(scope, *key_args)
      current_version(public_send(VERSION_KEY_METHODS.fetch(scope), *key_args))
    end

    def bump_version_for!(scope, *key_args)
      key = public_send(VERSION_KEY_METHODS.fetch(scope), *key_args)

      Redis::Alfred.with do |conn|
        conn.multi do |transaction|
          transaction.incr(key)
          transaction.expire(key, Conversations::UnreadCounts::FILTERED_COUNT_VERSION_TTL)
        end.first
      end
    end

    def claim_refresh_for!(scope, *key_args)
      claim_refresh_throttle(public_send(REFRESH_THROTTLE_KEY_METHODS.fetch(scope), *key_args))
    end

    def current_version(key)
      Redis::Alfred.get(key).to_i
    end

    def snapshot_payload(built_at)
      # expires_at marks the end of the fresh window. Redis keeps the snapshot for the additional stale window.
      {
        built_at: built_at.iso8601,
        refresh_after: (built_at + Conversations::UnreadCounts::FILTERED_COUNT_MIN_REFRESH_INTERVAL).iso8601,
        expires_at: (built_at + Conversations::UnreadCounts::FILTERED_COUNT_FRESH_TTL).iso8601
      }
    end

    def write_snapshot(key, payload)
      Redis::Alfred.setex(key, JSON.generate(payload), Conversations::UnreadCounts::FILTERED_COUNT_REDIS_TTL)
    end

    def read_snapshot(key)
      value = Redis::Alfred.get(key)
      return if value.blank?

      JSON.parse(value, symbolize_names: true)
    end

    def snapshot_state(snapshot, versions:, now:)
      return SnapshotResult.new(status: :missing, payload: nil) if snapshot.blank?
      return SnapshotResult.new(status: :expired, payload: snapshot) unless inside_stale_window?(snapshot, now)
      return SnapshotResult.new(status: :fresh, payload: snapshot) if versions_match?(snapshot, versions) && inside_fresh_window?(snapshot, now)

      SnapshotResult.new(status: :stale, payload: snapshot)
    end

    def versions_match?(snapshot, versions)
      versions.all? { |key, value| snapshot[key].to_i == value.to_i }
    end

    def inside_fresh_window?(snapshot, now)
      expires_at = parse_time(snapshot[:expires_at])
      expires_at.present? && now <= expires_at
    end

    def inside_stale_window?(snapshot, now)
      expires_at = parse_time(snapshot[:expires_at])
      expires_at.present? && now <= expires_at + Conversations::UnreadCounts::FILTERED_COUNT_STALE_WINDOW
    end

    def parse_time(value)
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      return value.to_time if value.respond_to?(:to_time) && !value.is_a?(String)

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def claim_refresh_throttle(key)
      Redis::Alfred.set(key, Time.current.to_i, nx: true, ex: Conversations::UnreadCounts::FILTERED_COUNT_MIN_REFRESH_INTERVAL) ? true : false
    end
  end
end
