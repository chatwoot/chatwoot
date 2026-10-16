module CacheKeysHelper
  def get_prefixed_cache_key(account_id, key)
    "idb-cache-key-account-#{account_id}-#{key}"
  end

  def fetch_value_for_key(account_id, key)
    prefixed_cache_key = get_prefixed_cache_key(account_id, key)
    value_from_cache = Redis::Alfred.get(prefixed_cache_key)

    return value_from_cache if value_from_cache.present?

    # The key expires after CacheKeys::CACHE_KEYS_EXPIRY. A constant fallback repeats after every
    # expiry, so a browser that cached data under it during an earlier gap would accept that stale
    # copy again. Start a fresh value instead; NX keeps concurrent readers on the same value.
    timestamp = (Time.now.utc.to_f * 1000).to_i.to_s
    Redis::Alfred.set(prefixed_cache_key, timestamp, nx: true, ex: CacheKeys::CACHE_KEYS_EXPIRY.to_i)
    Redis::Alfred.get(prefixed_cache_key) || timestamp
  end
end
