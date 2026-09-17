if redis.call('GET', KEYS[7]) ~= ARGV[1] or not redis.call('GET', KEYS[6]) then return 'stale' end
local now = tonumber(ARGV[3])
for _, item in ipairs(cjson.decode(ARGV[5])) do
  local id = item.id
  if redis.call('HGET', KEYS[3], id) == ARGV[4] then
    redis.call('HDEL', KEYS[3], id)
    if redis.call('HGET', KEYS[2], id) ~= item.revision then
      redis.call('ZADD', KEYS[1], now, id)
    elseif item.state == 'retry' then
      local attempts = redis.call('HINCRBY', KEYS[8], id, 1)
      redis.call('ZADD', KEYS[1], now + 30 * 2 ^ math.min(attempts - 1, 6), id)
    else
      redis.call('ZREM', KEYS[1], id)
      redis.call('ZREM', KEYS[9], id)
      redis.call('HDEL', KEYS[8], id)
      if item.state == 'failed' then
        redis.call('HSET', KEYS[4], id, cjson.encode(item))
      else
        redis.call('HDEL', KEYS[2], id)
        redis.call('HDEL', KEYS[4], id)
      end
    end
  end
end
local first = redis.call('ZRANGE', KEYS[1], 0, 0, 'WITHSCORES')
if #first > 0 then
  redis.call('ZADD', KEYS[5], first[2], ARGV[2])
else
  redis.call('ZREM', KEYS[5], ARGV[2])
end
return 1

