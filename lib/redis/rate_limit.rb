# Redis::RateLimit counts hits on a key in a fixed window that starts at the first hit.
# Use it for limits such as "5 codes per hour" or "5 wrong codes per code".
#
# Example Usage:
#
# rate_limit = Redis::RateLimit.new("SENDS::#{user.id}", limit: 5, window: 1.hour)
# return :rate_limited if rate_limit.exceeded?
#
# exceeded? counts the hit before it compares, so parallel requests cannot all pass under the limit.
class Redis::RateLimit
  pattr_initialize :key, [:limit!, :window!]

  def exceeded?
    count = Redis::Alfred.incr(key)
    # Also sets the expiry on a counter left without one by a failure between INCR and EXPIRE
    Redis::Alfred.expire(key, window.to_i) if count == 1 || Redis::Alfred.ttl(key).to_i.negative?
    count > limit
  end

  def remaining
    [limit - Redis::Alfred.get(key).to_i, 0].max
  end
end
