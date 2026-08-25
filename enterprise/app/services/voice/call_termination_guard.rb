class Voice::CallTerminationGuard
  TOKEN_KEY = 'agent_termination_token'.freeze
  STARTED_AT_KEY = 'agent_termination_started_at'.freeze
  DISCONNECT_SUPPRESS_CALL_SID_KEY = 'agent_disconnect_suppress_call_sid'.freeze
  STALE_AFTER = 2.minutes

  class << self
    def active?(call, now: Time.zone.now)
      return false if token(call).blank?

      started_at(call) >= now - STALE_AFTER
    end

    def clear_stale!(call, now: Time.zone.now)
      return false if token(call).blank? || active?(call, now: now)

      call.update!(meta: cleared_meta(call))
      true
    end

    def claim_meta(call, token:, now: Time.zone.now)
      cleared_meta(call).merge(
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

    def suppress_local_disconnect!(call, participant_call_sid)
      return false if participant_call_sid.blank?

      call.update!(meta: call.meta.merge(DISCONNECT_SUPPRESS_CALL_SID_KEY => participant_call_sid))
      true
    end

    def consume_local_disconnect!(call, participant_call_sid)
      return false if participant_call_sid.blank?
      return false unless call.meta[DISCONNECT_SUPPRESS_CALL_SID_KEY] == participant_call_sid

      call.update!(meta: call.meta.except(DISCONNECT_SUPPRESS_CALL_SID_KEY))
      true
    end

    private

    def token(call)
      call.meta[TOKEN_KEY]
    end

    def started_at(call)
      value = call.meta[STARTED_AT_KEY]
      return Time.zone.at(value.to_i) if value.to_i.positive?

      # Backward compatibility for guards written before STARTED_AT_KEY existed.
      # They remain protected briefly, then recover automatically.
      call.updated_at
    end

    def cleared_meta(call)
      call.meta.except(TOKEN_KEY, STARTED_AT_KEY)
    end
  end
end
