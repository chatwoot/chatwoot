require Rails.root.join('lib/redis/config')
require Rails.root.join('lib/captain_response_dequeued_logger')

schedule_file = 'config/schedule.yml'

Sidekiq.configure_client do |config|
  config.redis = Redis::Config.app
end

Sidekiq.configure_server do |config|
  config.redis = Redis::Config.app

  config.server_middleware do |chain|
    chain.add CaptainResponseDequeuedLogger
  end

  # Keep production job logs compact and JSON-formatted for the log collector.
  # LOG_LEVEL is set to `warn` on the sidekiq compose service to silence the
  # per-job info chatter; default to `info` elsewhere.
  if Rails.env.production?
    config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
    config[:skip_default_job_logging] = true
    config.logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'info').upcase)
  end
end

# https://github.com/ondrejbartas/sidekiq-cron
Rails.application.reloader.to_prepare do
  # load_from_hash! upserts jobs from the YAML and removes any Redis-persisted
  # jobs that share the same source tag but are no longer in the file.
  # This ensures deleted schedule entries are cleaned up on deploy.
  if File.exist?(schedule_file) && Sidekiq.server?
    schedule = YAML.load_file(schedule_file)

    # Cron entries removed from schedule.yml but possibly still in Redis
    # with source:'dynamic' (predating the source tag). load_from_hash!
    # only cleans up source:'schedule' entries, so these need explicit removal.
    # Remove names from this list once they've been through a deploy cycle.
    %w[bulk_auto_assignment_job].each { |name| Sidekiq::Cron::Job.destroy(name) }

    Sidekiq::Cron::Job.load_from_hash!(schedule, source: 'schedule')
  end
end
