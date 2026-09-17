if redis.call('GET', KEYS[7]) ~= ARGV[1] or not redis.call('GET', KEYS[6]) then return 'stale' end
local now = tonumber(ARGV[3])
redis.call('SET', KEYS[11], 1)
for i = 4, #ARGV do
  local id = ARGV[i]
  local revision = redis.call('INCR', KEYS[6])
  redis.call('HSET', KEYS[2], id, revision)
  redis.call('HDEL', KEYS[4], id)
  redis.call('ZADD', KEYS[1], 'NX', now, id)
  redis.call('ZADD', KEYS[9], 'NX', now, id)
end
local first = redis.call('ZRANGE', KEYS[1], 0, 0, 'WITHSCORES')
if #first > 0 then redis.call('ZADD', KEYS[5], first[2], ARGV[2]) end
return #ARGV - 3
