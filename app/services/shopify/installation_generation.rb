class Shopify::InstallationGeneration
  KEY = 'shopify_installation_generation'.freeze

  class Changed < StandardError; end

  class << self
    # Hold the shop lock across database commits so uninstall cannot miss a newly created hook.
    def with_shop_lock(shop)
      lock_id = Digest::SHA256.hexdigest("shopify:#{Shopify::ShopDomain.normalize(shop)}")[0, 15].to_i(16)
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute("SELECT pg_advisory_lock(#{lock_id})")
        begin
          yield
        ensure
          connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
        end
      end
    end

    def current(account)
      account.internal_attributes[KEY].to_i
    end

    def with_current!(account, expected_generation)
      changed = false
      result = nil
      account.with_lock do
        if current(account) == expected_generation
          result = yield
        else
          changed = true
        end
      end
      raise Changed, 'Shopify installation changed during authorization' if changed

      result
    end

    def advance!(account)
      account.update!(internal_attributes: account.internal_attributes.merge(KEY => current(account) + 1))
    end
  end
end
