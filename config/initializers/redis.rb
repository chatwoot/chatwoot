require "redis"

#for reports
config = YAML::load_file(File.join(Rails.root, 'config', 'reports_redis.yml'))[Rails.env]
redis = Redis.new(host: config["host"], port: config["port"])
namespace = config["namespace"]
Nightfury.redis = Redis::Namespace.new(namespace << "reports", redis: redis)

=begin
Alfred - Used currently for Round Robin. Add here as you use it for more features
=end
$alfred = Redis::Namespace.new(namespace << "alfred", :redis => redis, :warning => true)

