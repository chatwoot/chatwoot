module AccountCacheRevalidator
  extend ActiveSupport::Concern

  included do
    after_save :update_account_cache
    after_destroy :update_account_cache
    after_create :update_account_cache
  end

  def update_account_cache
    account.update_cache_key(self.class.name.underscore)
  end
end
