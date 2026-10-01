class Shopify::InstallationGeneration
  KEY = 'shopify_installation_generation'.freeze

  class Changed < StandardError; end

  class << self
    # Serialize installation and cleanup even when no hook exists yet.
    def with_shop_lock(shop)
      lock_id = Digest::SHA256.hexdigest("shopify:#{Shopify::ShopDomain.normalize(shop)}")[0, 15].to_i(16)
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")
        yield
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
