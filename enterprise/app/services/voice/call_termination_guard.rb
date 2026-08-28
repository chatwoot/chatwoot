class Voice::CallTerminationGuard
  TOKEN_KEY = 'agent_termination_token'.freeze
  STARTED_AT_KEY = 'agent_termination_started_at'.freeze
  DISCONNECT_SUPPRESS_CALL_SID_KEY = 'agent_disconnect_suppress_call_sid'.freeze
  PENDING_STATUS_KEY = 'agent_termination_pending_status'.freeze
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

    def release!(call, token)
      return false unless owned_by?(call, token)

      call.update!(meta: cleared_meta(call))
      true
    end

    def persist_pending_status!(call, status:, duration:, timestamp:)
      call.update!(
        meta: call.meta.merge(
          PENDING_STATUS_KEY => {
            'status' => status,
            'duration' => duration,
            'timestamp' => timestamp
          }.compact
        )
      )
    end

    def pending_status(call)
      call.meta[PENDING_STATUS_KEY]
    end

    def clear_pending_status!(call)
      return false if pending_status(call).blank?

      call.update!(meta: call.meta.except(PENDING_STATUS_KEY))
      true
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

    def cleared_ownership_meta(call)
      call.meta.except(TOKEN_KEY, STARTED_AT_KEY)
    end

    def cleared_meta(call)
      cleared_ownership_meta(call).except(PENDING_STATUS_KEY)
    end
  end
end
