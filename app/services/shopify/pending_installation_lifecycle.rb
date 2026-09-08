class Shopify::PendingInstallationLifecycle
  STATE_TTL = 10.minutes
  LOCK_TTL = 30.seconds
  LOCK_WAIT = 2.seconds
  GENERATION_KEY = 'shopify_pending_install_generation:%<shop>s'.freeze
  AUTHORIZATION_KEY = 'shopify_pending_install_authorization:%<shop>s'.freeze
  LOCK_KEY = 'shopify_pending_install_lock:%<shop>s'.freeze

  class << self
    def generation(shop:)
      normalized_shop = normalized_shop!(shop)
      key = generation_key(normalized_shop)
      value = ::Redis::Alfred.get(key)
      ::Redis::Alfred.expire(key, STATE_TTL.to_i) if value.present?
      value.to_i
    end

    def start_authorization!(shop:, started_at: Time.current)
      normalized_shop = normalized_shop!(shop)

      with_lock!(shop: normalized_shop) do
        ::Redis::Alfred.set(authorization_key(normalized_shop), started_at.utc.iso8601(6), ex: STATE_TTL.to_i)
        { generation: generation(shop: normalized_shop), started_at: started_at.utc.iso8601(6) }
      end
    end

    def invalidate!(shop:, occurred_at: nil)
      normalized_shop = Shopify::ShopDomain.normalize(shop)
      return false unless Shopify::ShopDomain.valid?(normalized_shop)

      with_lock!(shop: normalized_shop) do
        return false if stale_cleanup_event?(shop: normalized_shop, occurred_at: occurred_at)

        key = generation_key(normalized_shop)
        ::Redis::Alfred.with do |connection|
          connection.multi do |transaction|
            transaction.incr(key)
            transaction.expire(key, STATE_TTL.to_i)
          end
        end
        true
      end
    end

    def with_lock!(shop:)
      normalized_shop = normalized_shop!(shop)
      key = lock_key(normalized_shop)
      token = SecureRandom.uuid
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + LOCK_WAIT
      acquire_lock!(key, token, deadline)
      yield
    ensure
      ::Redis::Alfred.delete_if_equals(key, token) if key && token
    end

    private

    def acquire_lock!(key, token, deadline)
      until ::Redis::Alfred.set(key, token, nx: true, ex: LOCK_TTL.to_i)
        raise Shopify::PendingInstallation::InvalidToken, 'Shopify installation is currently being updated' if
          Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

        sleep(0.01)
      end
    end

    def normalized_shop!(shop)
      normalized_shop = Shopify::ShopDomain.normalize(shop)
      raise Shopify::PendingInstallation::InvalidToken, 'Invalid shop domain' unless Shopify::ShopDomain.valid?(normalized_shop)

      normalized_shop
    end

    def generation_key(shop)
      format(GENERATION_KEY, shop: shop)
    end

    def authorization_key(shop)
      format(AUTHORIZATION_KEY, shop: shop)
    end

    def lock_key(shop)
      format(LOCK_KEY, shop: shop)
    end

    def stale_cleanup_event?(shop:, occurred_at:)
      return false if occurred_at.blank?

      started_at = ::Redis::Alfred.get(authorization_key(shop))
      started_at.present? && occurred_at < Time.iso8601(started_at)
    rescue ArgumentError
      false
    end
  end
end
