class Widget::RedirectToken
  DEFAULT_TTL = 24.hours.to_i
  KEY_PREFIX = 'WIDGET_REDIRECT_TOKEN'.freeze

  class << self
    def generate(payload, ttl: DEFAULT_TTL)
      token = SecureRandom.urlsafe_base64(18)
      ::Redis::Alfred.set(key(token), payload.to_json, ex: ttl)
      token
    end

    def consume(token)
      return if token.blank?

      # Atomic get-and-delete so a token can never be consumed twice by concurrent
      # requests. GETDEL is not namespaced by redis-namespace, so use MULTI/EXEC.
      raw, = ::Redis::Alfred.with do |conn|
        conn.multi do |transaction|
          transaction.get(key(token))
          transaction.del(key(token))
        end
      end
      return if raw.blank?

      JSON.parse(raw)
    end

    private

    def key(token)
      "#{KEY_PREFIX}::#{token}"
    end
  end
end
