module Passkeys
  CHALLENGE_TTL = 5.minutes

  def self.enabled?
    ENV.fetch('FRONTEND_URL', nil).present? &&
      ActiveModel::Type::Boolean.new.cast(GlobalConfig.get_value('PASSKEYS_ENABLED')).present?
  end

  # Single-use read. Not GETDEL: redis-namespace passes it through without
  # prefixing the key, so it would never find the value.
  def self.consume(key)
    Redis::Alfred.with do |conn|
      conn.multi do |transaction|
        transaction.get(key)
        transaction.del(key)
      end
    end.first
  end

  def self.relying_party
    origin = URI.join(ENV.fetch('FRONTEND_URL'), '/').to_s.chomp('/')
    WebAuthn::RelyingParty.new(
      id: URI.parse(origin).host,
      name: GlobalConfig.get_value('INSTALLATION_NAME').presence || 'Chatwoot',
      allowed_origins: [origin]
    )
  end
end
