class Shopify::InstallationGeneration
  KEY = 'shopify_installation_generation'.freeze

  class Changed < StandardError; end

  class << self
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
