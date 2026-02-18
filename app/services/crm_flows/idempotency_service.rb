module CrmFlows
  class IdempotencyService
    TTL_SECONDS = 24 * 60 * 60
    KEY_PREFIX = 'crm_flow:idempotency'

    def self.check(key)
      raw = $alfred.with { |conn| conn.get("#{KEY_PREFIX}:#{key}") }
      return nil if raw.nil?

      JSON.parse(raw)
    end

    def self.store_pending(key, flow_id:, conversation_id:)
      data = {
        status: 'pending',
        flow_id: flow_id,
        conversation_id: conversation_id,
        created_at: Time.current.iso8601
      }
      $alfred.with { |conn| conn.set("#{KEY_PREFIX}:#{key}", data.to_json, ex: TTL_SECONDS) }
    end

    def self.store_completed(key, response:)
      data = {
        status: 'completed',
        response: response,
        completed_at: Time.current.iso8601
      }
      $alfred.with { |conn| conn.set("#{KEY_PREFIX}:#{key}", data.to_json, ex: TTL_SECONDS) }
    end

    def self.store_failed(key, error:)
      data = {
        status: 'failed',
        error: error,
        failed_at: Time.current.iso8601
      }
      $alfred.with { |conn| conn.set("#{KEY_PREFIX}:#{key}", data.to_json, ex: TTL_SECONDS) }
    end
  end
end
