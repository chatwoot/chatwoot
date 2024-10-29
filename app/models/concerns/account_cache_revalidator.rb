module AccountCacheRevalidator
  extend ActiveSupport::Concern

  included do
    after_commit :update_account_cache, on: [:create, :update, :destroy]
  end

  def update_account_cache
    account.update_cache_key(self.class.name.underscore)
  end
end
