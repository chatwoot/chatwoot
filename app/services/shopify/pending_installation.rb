class Shopify::PendingInstallation
  class Error < StandardError; end
  class InvalidToken < Error; end
  class AlreadyClaimed < Error; end
  class CommitOutcomeUnknown < Error; end
  class FeatureDisabled < Error; end
  class DuplicateShop < Error; end

  PAYLOAD_TTL = 10.minutes
  CLAIM_TTL = 1.minute
  TOKEN_FORMAT = /\A[0-9a-f]{32}\z/
  PAYLOAD_KEY = 'shopify_pending_install:%<token>s'.freeze
  CLAIM_KEY = 'shopify_pending_install_claim:%<token>s'.freeze
  GENERATION_KEY = 'shopify_pending_install_generation:%<shop>s'.freeze

  attr_reader :data

  def self.create(access_token:, shop:, scope:, shop_generation: nil)
    token = SecureRandom.hex(16)
    normalized_shop = Shopify::ShopDomain.normalize(shop)
    raise InvalidToken, 'Invalid shop domain' unless Shopify::ShopDomain.valid?(normalized_shop)

    current_generation = generation(shop: normalized_shop)
    raise InvalidToken, 'Shopify installation is no longer active' if shop_generation.present? && shop_generation.to_i != current_generation

    payload = { access_token: access_token, shop: normalized_shop, scope: scope, generation: current_generation }
    Redis::SecureStorage.set(payload_key(token), payload, PAYLOAD_TTL)
    token
  end

  def self.generation(shop:)
    normalized_shop = Shopify::ShopDomain.normalize(shop)
    return 0 unless Shopify::ShopDomain.valid?(normalized_shop)

    key = generation_key(normalized_shop)
    value = ::Redis::Alfred.get(key)
    ::Redis::Alfred.expire(key, PAYLOAD_TTL.to_i) if value.present?
    value.to_i
  end

  def self.invalidate_shop!(shop:)
    normalized_shop = Shopify::ShopDomain.normalize(shop)
    return unless Shopify::ShopDomain.valid?(normalized_shop)

    key = generation_key(normalized_shop)
    ::Redis::Alfred.with do |connection|
      connection.multi do |transaction|
        transaction.incr(key)
        transaction.expire(key, PAYLOAD_TTL.to_i)
      end
    end
  end

  def self.claim(token:, account_id: nil)
    raise InvalidToken, 'Invalid or expired install token' unless token.is_a?(String) && token.match?(TOKEN_FORMAT)

    claim_token = SecureRandom.uuid
    claim_key = claim_key(token)
    claimed = ::Redis::Alfred.set(claim_key, claim_token, nx: true, ex: CLAIM_TTL.to_i)
    raise AlreadyClaimed, 'Install token is already being used' unless claimed

    new(token: token, claim_key: claim_key, claim_token: claim_token, account_id: account_id)
  rescue StandardError
    ::Redis::Alfred.delete_if_equals(claim_key, claim_token) if claim_key && claim_token
    raise
  end

  def self.pending?(token:)
    return false unless token.is_a?(String) && token.match?(TOKEN_FORMAT)

    data = JSON.parse(Redis::SecureStorage.get(payload_key(token)).to_s)
    shop = Shopify::ShopDomain.normalize(data['shop'])
    Shopify::ShopDomain.valid?(shop) && data['generation'].to_i == generation(shop: shop)
  rescue JSON::ParserError, TypeError
    false
  end

  def initialize(token:, claim_key:, claim_token:, account_id:)
    @token = token
    @claim_key = claim_key
    @claim_token = claim_token
    @data = load_data
    if account_id
      bind_to_account!(account_id)
    elsif data['account_id'].present?
      raise InvalidToken, 'Install token is already bound to an account'
    end
  end

  def consume!
    consumed = false

    ::Redis::Alfred.with do |connection|
      connection.watch(@claim_key) do
        next unless connection.get(@claim_key) == @claim_token

        consumed = connection.multi do |transaction|
          transaction.del(payload_key)
          transaction.del(@claim_key)
        end.present?
      end
    end

    raise AlreadyClaimed, 'Install token claim has expired' unless consumed
  rescue AlreadyClaimed
    raise
  rescue StandardError => e
    state = consume_state
    return if state == :consumed
    raise e if state == :not_consumed

    raise CommitOutcomeUnknown, 'Install token consumption outcome is unknown', cause: e
  end

  def bind_to_account!(account_id)
    bound_account_id = data['account_id']
    raise InvalidToken, 'Install token cannot be used by this account' if bound_account_id.present? && bound_account_id != account_id
    return if bound_account_id == account_id

    persist_data(data.merge('account_id' => account_id))
    @data['account_id'] = account_id
    @bound_by_claim = true
  end

  def release!(unbind: false)
    unbind_from_account! if unbind && @bound_by_claim
    ::Redis::Alfred.delete_if_equals(@claim_key, @claim_token)
  end

  class << self
    private

    def payload_key(token)
      format(PAYLOAD_KEY, token: token)
    end

    def claim_key(token)
      format(CLAIM_KEY, token: token)
    end

    def generation_key(shop)
      format(GENERATION_KEY, shop: shop)
    end
  end

  private

  def persist_data(updated_data)
    ttl = ::Redis::Alfred.ttl(payload_key)
    raise InvalidToken, 'Invalid or expired install token' unless ttl.positive?

    Redis::SecureStorage.set(payload_key, updated_data, ttl)
  end

  def unbind_from_account!
    persist_data(data.except('account_id'))
  rescue InvalidToken
    nil
  end

  def consume_state
    payload, claim = ::Redis::Alfred.with do |connection|
      connection.mget(payload_key, @claim_key)
    end
    return :consumed if payload.nil? && claim.nil?
    return :not_consumed if payload.present?

    :unknown
  rescue StandardError
    :unknown
  end

  def load_data
    json_data = Redis::SecureStorage.get(payload_key)
    raise InvalidToken, 'Invalid or expired install token' if json_data.blank?

    data = JSON.parse(json_data)
    raise InvalidToken, 'Invalid or expired install token' unless data.is_a?(Hash)

    required_values = data.values_at('access_token', 'shop', 'scope')
    raise InvalidToken, 'Invalid or expired install token' unless required_values.all?(&:present?)

    data['shop'] = Shopify::ShopDomain.normalize(data['shop'])
    raise InvalidToken, 'Invalid or expired install token' unless Shopify::ShopDomain.valid?(data['shop'])

    verify_shop_generation!(data)

    data
  rescue JSON::ParserError, TypeError
    raise InvalidToken, 'Invalid or expired install token'
  end

  def verify_shop_generation!(data)
    return if data['generation'].to_i == self.class.generation(shop: data['shop'])

    raise InvalidToken, 'Invalid or expired install token'
  end

  def payload_key
    format(PAYLOAD_KEY, token: @token)
  end
end
