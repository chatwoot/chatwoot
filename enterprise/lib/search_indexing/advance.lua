if redis.call('GET', KEYS[7]) ~= ARGV[1] or not redis.call('GET', KEYS[6]) then return 'stale' end
for id, revision in pairs(cjson.decode(ARGV[5])) do
  if redis.call('HGET', KEYS[3], id) == ARGV[4] then
    if redis.call('HGET', KEYS[2], id) == revision then
      redis.call('HSET', KEYS[10], id, revision .. ':' .. ARGV[6])
    end
    redis.call('HDEL', KEYS[3], id)
    redis.call('ZADD', KEYS[1], ARGV[3], id)
  end
end
local first = redis.call('ZRANGE', KEYS[1], 0, 0, 'WITHSCORES')
if #first > 0 then redis.call('ZADD', KEYS[5], first[2], ARGV[2]) end
return 1
