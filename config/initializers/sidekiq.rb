schedule_file = 'config/schedule.yml'

Sidekiq.configure_client do |config|
  config.redis = Redis::Config.sidekiq
end

Sidekiq.configure_server do |config|
  config.redis = Redis::Config.sidekiq
end

# https://github.com/ondrejbartas/sidekiq-cron
Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file) && Sidekiq.server?
