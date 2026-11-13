if redis.call('GET', KEYS[7]) ~= ARGV[1] or not redis.call('GET', KEYS[6]) then return 'stale' end
local page = redis.call('HSCAN', KEYS[4], ARGV[5], 'COUNT', ARGV[4])
local entries = page[2]
for i = 1, #entries, 2 do
  local id = entries[i]
  redis.call('ZADD', KEYS[1], ARGV[3], id)
  redis.call('ZADD', KEYS[9], 'NX', ARGV[3], id)
  redis.call('HDEL', KEYS[4], id)
end
if #entries > 0 then redis.call('ZADD', KEYS[5], ARGV[3], ARGV[2]) end
return { page[1], #entries / 2 }
