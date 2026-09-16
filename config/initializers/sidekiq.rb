require Rails.root.join('lib/redis/config')
require Rails.root.join('lib/captain_response_dequeued_logger')

schedule_file = 'config/schedule.yml'

Sidekiq.configure_client do |config|
  config.redis = Redis::Config.app
end

# Logs whenever a job is pulled off Redis for execution.
class ChatwootDequeuedLogger
  def call(_worker, job, queue)
    payload = job['args'].first
    Sidekiq.logger.info("Dequeued #{job['wrapped']} #{payload['job_id']} from #{queue}")
    yield
  end
end

Sidekiq.configure_server do |config|
  config.redis = Redis::Config.app

  config.server_middleware do |chain|
    chain.add CaptainResponseDequeuedLogger

    chain.add ChatwootDequeuedLogger if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_SIDEKIQ_DEQUEUE_LOGGER', false))
  end

  # skip the default start stop logging
  if Rails.env.production?
    config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
    config[:skip_default_job_logging] = true
    config.logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'info').upcase.to_s)
  end
end

# Publish Sidekiq queue metrics (latency, depth) to CloudWatch for autoscaling.
# Opt-in via ENABLE_SIDEKIQ_CLOUDWATCH, and gated on Sidekiq.server? so the AWS
# client and credential lookup run only in the Sidekiq process, never in web,
# console, or rake.
if Sidekiq.server? && ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_SIDEKIQ_CLOUDWATCH', false))
  require 'speedshop/cloudwatch'
  require 'speedshop/cloudwatch/sidekiq'

  # Use the instance role by default. Do not fall through to the default AWS chain: the shared
  # AWS_ACCESS_KEY_ID is scoped to storage (S3) and would lack cloudwatch:PutMetricData.
  # Dedicated keys can be supplied to override when an instance role is not available.
  cloudwatch_credentials =
    if ENV['SIDEKIQ_CLOUDWATCH_AWS_ACCESS_KEY_ID'].present?
      Aws::Credentials.new(ENV.fetch('SIDEKIQ_CLOUDWATCH_AWS_ACCESS_KEY_ID'), ENV.fetch('SIDEKIQ_CLOUDWATCH_AWS_SECRET_ACCESS_KEY'))
    else
      Aws::InstanceProfileCredentials.new
    end

  # Region: dedicated override, else the shared storage region, else a default. Uses presence
  # so a present-but-blank env var (as .env.example ships AWS_REGION=) does not become "".
  cloudwatch_region = ENV['SIDEKIQ_CLOUDWATCH_AWS_REGION'].presence || ENV['AWS_REGION'].presence || 'us-east-1'

  # Interval: fall back to the 60s default unless a positive integer is given. This only rejects
  # blank/zero/negative/non-numeric values (which would make the reporter busy-loop); a valid
  # sub-60 value is honoured, though it bills as high-resolution CloudWatch metrics.
  configured_interval = Integer(ENV.fetch('SIDEKIQ_CLOUDWATCH_INTERVAL', 60), exception: false)
  cloudwatch_interval = configured_interval&.positive? ? configured_interval : 60

  Speedshop::Cloudwatch.configure do |cw|
    cw.client = Aws::CloudWatch::Client.new(region: cloudwatch_region, credentials: cloudwatch_credentials)
    cw.namespaces[:sidekiq] = ENV.fetch('SIDEKIQ_CLOUDWATCH_NAMESPACE', 'Chatwoot/Sidekiq')
    cw.interval = cloudwatch_interval
    cw.metrics[:sidekiq] = %i[QueueLatency QueueSize EnqueuedJobs Utilization]
    cw.enabled_environments = [cw.environment]
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
