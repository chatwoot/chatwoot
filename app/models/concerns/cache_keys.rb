module CacheKeys
  extend ActiveSupport::Concern

  def get_prefixed_cache_key(key)
    "idb-cache-key-#{self.class.name.underscore}_#{id}_#{key}"
  end

  def fetch_value_for_key(key)
    prefixed_cache_key = get_prefixed_cache_key(key)
    value_from_cache = Redis::Alfred.get(prefixed_cache_key)

    return value_from_cache if value_from_cache.present?

    # zero epoch time: 1970-01-01 00:00:00 UTC
    '0000000000'
  end

  def cache_keys
    {
      label: fetch_value_for_key(Label.name.underscore),
      inbox: fetch_value_for_key(Inbox.name.underscore),
      team: fetch_value_for_key(Team.name.underscore)
    }
  end

  def invalidate_cache_key_for(key)
    prefixed_cache_key = get_prefixed_cache_key(key)
    Redis::Alfred.del(prefixed_cache_key)
  end

  def update_cache_key(key)
    prefixed_cache_key = get_prefixed_cache_key(key)
    Redis::Alfred.set(prefixed_cache_key, Time.now.utc.to_i)
  end
end
