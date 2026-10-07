class Conversations::UnreadCounts::FilteredCountSnapshotResolver
  BUILD_LOCK_TTL = 15.minutes.to_i

  attr_reader :account, :now, :store, :lock_manager

  def initialize(account:, now:, store:, lock_manager:)
    @account = account
    @now = now
    @store = store
    @lock_manager = lock_manager
  end

  # Version mismatches make a snapshot stale immediately, but refresh_after keeps DB rebuilds throttled.
  def resolve(scope:, state:, lock_key:, claim_refresh:, &)
    record_snapshot_state(scope, state)
    return state.payload if state.fresh?

    stale_payload = state.payload if state.stale?
    return stale_payload if refresh_not_due?(stale_payload)
    return stale_payload unless refresh_claimed?(scope, claim_refresh)

    build_with_lock(scope, lock_key, stale_payload, &)
  end

  private

  def record_snapshot_state(scope, state)
    instrumentation.increment(
      :snapshot_state,
      account_id: account.id,
      snapshot_scope: scope,
      snapshot_status: state.status
    )
  end

  def refresh_not_due?(stale_payload)
    stale_payload.present? && !store.refresh_due?(stale_payload, now: now)
  end

  def refresh_claimed?(scope, claim_refresh)
    claimed = claim_refresh.call
    instrumentation.increment(:refresh_claim, account_id: account.id, snapshot_scope: scope, claimed: claimed)
    claimed
  end

  def build_with_lock(scope, lock_key, stale_payload, &)
    built_payload = nil
    lock_acquired = false

    begin
      lock_manager.with_lock(lock_key, BUILD_LOCK_TTL) do
        lock_acquired = true
        built_payload = instrumentation.observe(:snapshot_build, account_id: account.id, snapshot_scope: scope, &)
      rescue ActiveRecord::StatementInvalid
        built_payload = stale_payload
      end
    ensure
      instrumentation.increment(:build_lock, account_id: account.id, snapshot_scope: scope, acquired: lock_acquired)
    end

    lock_acquired ? built_payload : stale_payload
  end

  def instrumentation
    ::Conversations::UnreadCounts::FilteredCountInstrumentation
  end
end
