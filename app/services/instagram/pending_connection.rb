class Instagram::PendingConnection
  EXPIRATION = 10.minutes

  def self.create(account_id:, **attributes)
    token = SecureRandom.hex(32)
    Redis::SecureStorage.set(cache_key(account_id, token), attributes, EXPIRATION)
    token
  end

  def self.cache_key(account_id, token)
    "instagram:pending_connection:#{account_id}:#{token}"
  end

  def initialize(account:, token:)
    @account = account
    @key = self.class.cache_key(account.id, token)
    payload = Redis::SecureStorage.get(@key)
    @attributes = JSON.parse(payload).with_indifferent_access if payload
    raise Instagram::UnifiedLoginService::Error, I18n.t('instagram.connection_expired') unless @attributes
  end

  def accounts
    @attributes.fetch(:accounts)
  end

  def connect(instagram_id)
    instagram_account = accounts.find { |item| item.fetch('id') == instagram_id }
    raise Instagram::UnifiedLoginService::Error, I18n.t('instagram.invalid_account') unless instagram_account

    # The callback already filtered accounts; only check that its target still exists.
    @account.inboxes.where(channel_type: 'Channel::Instagram').find(@attributes[:inbox_id]) if @attributes[:inbox_id]

    inbox, already_exists = Instagram::UnifiedInboxBuilder.new(
      account: @account, token_response: @attributes.fetch(:token_response),
      instagram_account: instagram_account, configuration_id: @attributes.fetch(:configuration_id)
    ).perform
    Redis::SecureStorage.delete(@key)
    { inbox: inbox, already_exists: already_exists, return_to: @attributes[:return_to] }
  end
end
