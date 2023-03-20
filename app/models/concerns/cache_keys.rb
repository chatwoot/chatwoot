module CacheKeys
  extend ActiveSupport::Concern

  include CacheKeysHelper
  include Events::Types

  def cache_keys
    {
      label: fetch_value_for_key(id, Label.name.underscore),
      inbox: fetch_value_for_key(id, Inbox.name.underscore),
      team: fetch_value_for_key(id, Team.name.underscore)
    }
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

  private

  def dispatch_cache_udpate_event
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CACHE_INVALIDATED, Time.zone.now, cache_keys: cache_keys, account: self)
  end
end
