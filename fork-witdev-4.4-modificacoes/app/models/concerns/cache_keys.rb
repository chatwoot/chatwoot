module CacheKeys
  extend ActiveSupport::Concern

  include CacheKeysHelper
  include Events::Types

  CACHE_KEYS_EXPIRY = 72.hours

  included do
    class_attribute :cacheable_models
    self.cacheable_models = [Label, Inbox, Team]
  end

  def cache_keys
    keys = {}
    self.class.cacheable_models.each do |model|
      keys[model.name.underscore.to_sym] = fetch_value_for_key(id, model.name.underscore)
    end

    keys
  end

  def update_cache_key(key)
    update_cache_key_for_account(id, key)
    dispatch_cache_update_event
  end

  def reset_cache_keys
    self.class.cacheable_models.each do |model|
      update_cache_key_for_account(id, model.name.underscore)
    end

    dispatch_cache_update_event
  end

  private

  def update_cache_key_for_account(account_id, key)
    prefixed_cache_key = get_prefixed_cache_key(account_id, key)
    Redis::Alfred.setex(prefixed_cache_key, Time.now.utc.to_i, CACHE_KEYS_EXPIRY)
  end

  def dispatch_cache_update_event
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CACHE_INVALIDATED, Time.zone.now, cache_keys: cache_keys, account: self)
  end
end
