#for reports
#TODO fix the redis config
uri = URI.parse("redis://localhost:6379")
redis = Redis.new(:url => uri)
Nightfury.redis = Redis::Namespace.new("reports", redis: redis)

=begin
Alfred - Used currently for Round Robin. Add here as you use it for more features
=end
$alfred = Redis::Namespace.new("alfred", :redis => redis, :warning => true)

