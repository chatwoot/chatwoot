module CacheKeys
  extend ActiveSupport::Concern

  include CacheKeysHelper
  include Events::Types

  @cacheable_models = [Label, Inbox, Team]

  def cache_keys
    keys = {}
    @cacheable_models.each do |model|
      keys[model.name.underscore.to_sym] = fetch_value_for_key(id, model.name.underscore)
    end

    keys
  end

  def invalidate_cache_key_for(key)
    prefixed_cache_key = get_prefixed_cache_key(id, key)
    Redis::Alfred.del(prefixed_cache_key)
    dispatch_cache_udpate_event
  end

  def update_cache_key(key)
    prefixed_cache_key = get_prefixed_cache_key(id, key)
    Redis::Alfred.set(prefixed_cache_key, Time.now.utc.to_i)
    dispatch_cache_udpate_event
  end

  def reset_cache_keys
    @cacheable_models.each do |model|
      invalidate_cache_key_for(model.name.underscore)
    end
  end

  private

  def dispatch_cache_udpate_event
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CACHE_INVALIDATED, Time.zone.now, cache_keys: cache_keys, account: self)
  end
end
