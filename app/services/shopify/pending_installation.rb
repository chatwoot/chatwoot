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

  attr_reader :data

  def self.create(access_token:, shop:, scope:)
    token = SecureRandom.hex(16)
    normalized_shop = Shopify::ShopDomain.normalize(shop)
    raise InvalidToken, 'Invalid shop domain' unless Shopify::ShopDomain.valid?(normalized_shop)

    payload = { access_token: access_token, shop: normalized_shop, scope: scope }
    Redis::SecureStorage.set(payload_key(token), payload, PAYLOAD_TTL)
    token
  end

  def self.claim(token:)
    raise InvalidToken, 'Invalid or expired install token' unless token.is_a?(String) && token.match?(TOKEN_FORMAT)

    claim_token = SecureRandom.uuid
    claim_key = claim_key(token)
    claimed = ::Redis::Alfred.set(claim_key, claim_token, nx: true, ex: CLAIM_TTL.to_i)
    raise AlreadyClaimed, 'Install token is already being used' unless claimed

    new(token: token, claim_key: claim_key, claim_token: claim_token)
  rescue StandardError
    ::Redis::Alfred.delete_if_equals(claim_key, claim_token) if claim_key && claim_token
    raise
  end

  def self.pending?(token:)
    return false unless token.is_a?(String) && token.match?(TOKEN_FORMAT)

    Redis::SecureStorage.get(payload_key(token)).present?
  end

  def initialize(token:, claim_key:, claim_token:)
    @token = token
    @claim_key = claim_key
    @claim_token = claim_token
    @data = load_data
  end

  def consume!
    consumed = false

    ::Redis::Alfred.with do |connection|
      connection.watch(@claim_key) do
        next unless connection.get(@claim_key) == @claim_token

        consumed = connection.multi do |transaction|
          transaction.del(format(PAYLOAD_KEY, token: @token))
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

  def release!
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
  end

  private

  def consume_state
    payload, claim = ::Redis::Alfred.with do |connection|
      connection.mget(format(PAYLOAD_KEY, token: @token), @claim_key)
    end
    return :consumed if payload.nil? && claim.nil?
    return :not_consumed if payload.present?

    :unknown
  rescue StandardError
    :unknown
  end

  def load_data
    json_data = Redis::SecureStorage.get(format(PAYLOAD_KEY, token: @token))
    raise InvalidToken, 'Invalid or expired install token' if json_data.blank?

    data = JSON.parse(json_data)
    raise InvalidToken, 'Invalid or expired install token' unless data.is_a?(Hash)

    required_values = data.values_at('access_token', 'shop', 'scope')
    raise InvalidToken, 'Invalid or expired install token' unless required_values.all?(&:present?)

    data['shop'] = Shopify::ShopDomain.normalize(data['shop'])
    raise InvalidToken, 'Invalid or expired install token' unless Shopify::ShopDomain.valid?(data['shop'])

    data
  rescue JSON::ParserError, TypeError
    raise InvalidToken, 'Invalid or expired install token'
  end
end
