-- Losing either key fences all old jobs into their old physical indexes.
if not redis.call('GET', KEYS[1]) or not redis.call('GET', KEYS[2]) then
  redis.call('SET', KEYS[1], ARGV[1])
  redis.call('SET', KEYS[2], 0)
  redis.call('DEL', KEYS[3])
end
return redis.call('GET', KEYS[1])
