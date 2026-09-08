# Shared AWS setup for the speedshop-cloudwatch reporters. The Sidekiq and web reporters run in
# separate processes and configure the gem singleton independently, so each passes its own env
# prefix (SIDEKIQ_CLOUDWATCH_ or WEB_CLOUDWATCH_) and can be enabled on its own.
class CloudwatchReporterConfig
  DEFAULT_INTERVAL = 60
  DEFAULT_REGION = 'us-east-1'.freeze

  def initialize(env_prefix)
    @env_prefix = env_prefix
  end

  # Required here rather than at the top of the file: lib/ is eager loaded, and the AWS
  # CloudWatch SDK should only be pulled in when a reporter is actually switched on.
  def client
    require 'aws-sdk-cloudwatch'
    Aws::CloudWatch::Client.new(region: region, credentials: credentials)
  end

  # Falls back to the default unless a positive integer is given. This only rejects
  # blank/zero/negative/non-numeric values (which would make the reporter busy-loop); a valid
  # sub-60 value is honoured, though it bills as high-resolution CloudWatch metrics.
  def interval
    configured = Integer(prefixed_env('INTERVAL', DEFAULT_INTERVAL), exception: false)
    configured&.positive? ? configured : DEFAULT_INTERVAL
  end

  private

  # Use the instance role by default. Do not fall through to the default AWS chain: the shared
  # AWS_ACCESS_KEY_ID is scoped to storage (S3) and would lack cloudwatch:PutMetricData.
  # Dedicated keys can be supplied to override when an instance role is not available.
  def credentials
    access_key_id = prefixed_env('AWS_ACCESS_KEY_ID')
    return Aws::InstanceProfileCredentials.new if access_key_id.blank?

    secret_access_key = prefixed_env('AWS_SECRET_ACCESS_KEY')
    # Half a credential pair builds a client that fails on every flush rather than at boot, so
    # the metric would go missing with nothing pointing at the cause. Blank counts as missing,
    # since .env files carry empty assignments.
    raise ArgumentError, "#{@env_prefix}AWS_SECRET_ACCESS_KEY must be set alongside the access key id" if secret_access_key.blank?

    Aws::Credentials.new(access_key_id, secret_access_key)
  end

  # Dedicated override, else the shared storage region, else a default. Uses presence so a
  # present-but-blank env var (as .env.example ships AWS_REGION=) does not become "".
  def region
    prefixed_env('AWS_REGION') || ENV['AWS_REGION'].presence || DEFAULT_REGION
  end

  def prefixed_env(name, default = nil)
    ENV["#{@env_prefix}#{name}"].presence || default
  end
end
