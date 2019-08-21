require "redis"

#for reports
redis = Redis.new(url: ENV['REDIS_URL'])
Nightfury.redis = Redis::Namespace.new("reports", redis: redis)

=begin
Alfred - Used currently for Round Robin. Add here as you use it for more features
=end
$alfred = Redis::Namespace.new("alfred", :redis => redis, :warning => true)

