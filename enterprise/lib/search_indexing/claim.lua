if redis.call('GET', KEYS[7]) ~= ARGV[1] or not redis.call('GET', KEYS[6]) then return 'stale' end
local now = tonumber(ARGV[3])
local ids = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, ARGV[5])
if #ids == 0 then return {} end
local result = { tostring(redis.call('INCR', KEYS[6])) }
for _, id in ipairs(ids) do
  redis.call('HSET', KEYS[3], id, ARGV[6])
  redis.call('ZADD', KEYS[1], now + tonumber(ARGV[4]), id)
  table.insert(result, id)
  table.insert(result, redis.call('HGET', KEYS[2], id))
end
local first = redis.call('ZRANGE', KEYS[1], 0, 0, 'WITHSCORES')
redis.call('ZADD', KEYS[5], first[2], ARGV[2])
return result

