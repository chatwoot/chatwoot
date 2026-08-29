class Voice::CallTerminationGuard
  TOKEN_KEY = 'agent_termination_token'.freeze
  STARTED_AT_KEY = 'agent_termination_started_at'.freeze
  DISCONNECT_SUPPRESS_CALL_SID_KEY = 'agent_disconnect_suppress_call_sid'.freeze
  PENDING_STATUS_KEY = 'agent_termination_pending_status'.freeze
  PENDING_JOIN_KEY = 'agent_termination_pending_join'.freeze
  PENDING_OWNER_TOKEN_KEY = 'termination_token'.freeze
  STATUS_ORDER = {
    'ringing' => 0,
    'in_progress' => 1
  }.freeze
  STALE_AFTER = 2.minutes

  class << self
    def active?(call, now: Time.zone.now)
      return false if token(call).blank?

      started_at(call) >= now - STALE_AFTER
    end

    def clear_stale!(call, now: Time.zone.now)
      return false if token(call).blank? || active?(call, now: now)

      call.update!(meta: cleared_ownership_meta(call))
      true
    end

    def claim_meta(call, token:, now: Time.zone.now)
      cleared_ownership_meta(call).merge(
        TOKEN_KEY => token,
        STARTED_AT_KEY => now.to_i
      )
    end

    def owned_by?(call, token)
      token.present? && self.token(call) == token
    end

    def release!(call, token, clear_pending: true)
      return false unless owned_by?(call, token)

      meta = cleared_ownership_meta(call)
      meta = meta.except(PENDING_STATUS_KEY, PENDING_JOIN_KEY) if clear_pending
      call.update!(meta: meta)
      true
    end

    def persist_pending_status!(call, status:, duration:, timestamp:)
      existing_status = pending_status(call)&.dig('status')
      return false if preserve_existing_status?(existing_status, status)

      call.update!(
        meta: call.meta.merge(
          PENDING_STATUS_KEY => {
            'status' => status,
            'duration' => duration,
            'timestamp' => timestamp,
            PENDING_OWNER_TOKEN_KEY => token(call)
          }.compact
        )
      )
      true
    end

    def pending_status(call)
      call.meta[PENDING_STATUS_KEY]
    end

    def clear_pending_status!(call)
      return false if pending_status(call).blank?

      call.update!(meta: call.meta.except(PENDING_STATUS_KEY))
      true
    end

    def clear_pending_status_if_matches!(call, pending)
      return false if pending.blank? || pending_status(call) != pending

      clear_pending_status!(call)
    end

    def persist_pending_join!(call, participant_label:, participant_call_sid:, timestamp:)
      existing = pending_join(call)
      return false if earlier_or_same_join?(existing, timestamp)

      call.update!(
        meta: call.meta.merge(
          PENDING_JOIN_KEY => {
            'participant_label' => participant_label,
            'participant_call_sid' => participant_call_sid,
            'timestamp' => timestamp,
            PENDING_OWNER_TOKEN_KEY => token(call)
          }.compact
        )
      )
      true
    end

    def pending_join(call)
      call.meta[PENDING_JOIN_KEY]
    end

    def clear_pending_join!(call)
      return false if pending_join(call).blank?

      call.update!(meta: call.meta.except(PENDING_JOIN_KEY))
      true
    end

    def clear_pending_join_if_matches!(call, pending)
      return false if pending.blank? || pending_join(call) != pending

      clear_pending_join!(call)
    end

    def suppress_local_disconnect!(call, participant_call_sid)
      return false if participant_call_sid.blank?

      pending_sids = disconnect_suppress_call_sids(call)
      return true if pending_sids.include?(participant_call_sid)

      call.update!(meta: call.meta.merge(DISCONNECT_SUPPRESS_CALL_SID_KEY => pending_sids + [participant_call_sid]))
      true
    end

    def consume_local_disconnect!(call, participant_call_sid)
      return false if participant_call_sid.blank?

      pending_sids = disconnect_suppress_call_sids(call)
      return false unless pending_sids.include?(participant_call_sid)

      remaining_sids = pending_sids - [participant_call_sid]
      meta = if remaining_sids.empty?
               call.meta.except(DISCONNECT_SUPPRESS_CALL_SID_KEY)
             else
               call.meta.merge(DISCONNECT_SUPPRESS_CALL_SID_KEY => remaining_sids)
             end
      call.update!(meta: meta)
      true
    end

    private

    def token(call)
      call.meta[TOKEN_KEY]
    end

    def disconnect_suppress_call_sids(call)
      Array(call.meta[DISCONNECT_SUPPRESS_CALL_SID_KEY]).compact_blank.uniq
    end

    def started_at(call)
      value = call.meta[STARTED_AT_KEY]
      return Time.zone.at(value.to_i) if value.to_i.positive?

      call.updated_at
    end

    def terminal_status?(status)
      status.present? && Call::TERMINAL_STATUSES.include?(status)
    end

    def preserve_existing_status?(existing_status, new_status)
      return false if existing_status.blank?
      return true if terminal_status?(existing_status) && !terminal_status?(new_status)
      return false if terminal_status?(new_status)

      existing_order = STATUS_ORDER[existing_status]
      new_order = STATUS_ORDER[new_status]
      existing_order && new_order && existing_order >= new_order
    end

    def earlier_or_same_join?(existing, timestamp)
      return false if existing.blank?

      existing_timestamp = existing['timestamp'].to_i
      new_timestamp = timestamp.to_i
      existing_timestamp.positive? && (new_timestamp.zero? || existing_timestamp <= new_timestamp)
    end

    def cleared_ownership_meta(call)
      call.meta.except(TOKEN_KEY, STARTED_AT_KEY)
    end
  end
end
