# Gem requirements:
# gem 'aws-sdk-cloudwatch'
# (optional, only if IMDS tags are disabled and you want ASG lookup fallback)
# gem 'aws-sdk-ec2'
# rubocop:disable Metrics/ClassLength
require 'sidekiq/api'
require 'aws-sdk-cloudwatch'
require 'aws-sdk-ec2' # optional (see notes)
require 'net/http'
require 'timeout'
require 'json'

class SidekiqThreadUtilizationMonitoringJob < ApplicationJob
  queue_as :scheduled_jobs

  # Sidekiq compatibility
  attr_accessor :jid

  # Timeouts
  METADATA_TIMEOUT   = 10.seconds
  API_TIMEOUT        = 10.seconds
  TOTAL_JOB_TIMEOUT  = 12.seconds

  # Client cache
  @client_mutex        = Mutex.new
  @cached_client       = nil
  @client_created_at   = nil
  CLIENT_REFRESH_INTERVAL = 1.hour

  class << self
    attr_accessor :client_mutex, :cached_client, :client_created_at

    def clear_client_cache!
      @client_mutex.synchronize do
        @cached_client = nil
        @client_created_at = nil
      end
    end
  end

  def perform
    Timeout.timeout(TOTAL_JOB_TIMEOUT) { perform_job }
  rescue Timeout::Error
    Rails.logger.error 'SidekiqThreadUtilizationToCloudWatchJob: timeout reached'
  end

  def perform_job
    return unless should_run?

    detect_aws_metadata
    return unless required_env_vars_present?

    ratio = calculate_thread_utilization_ratio
    send_metrics_to_cloudwatch(ratio)
  rescue StandardError => e
    Rails.logger.error "SidekiqThreadUtilizationToCloudWatchJob: #{e.class} - #{e.message}"
  end

  private

  def should_run?
    aws_environment? || required_env_vars_present?
  end

  def required_env_vars_present?
    ENV['AWS_REGION'].present? && ENV['AWS_INSTANCE_ID'].present?
    # ENV['AWS_AUTO_SCALING_GROUP_NAME'] is optional but recommended for ASG-based alarms
  end

  # ---------- Sidekiq utilization ----------
  def calculate_thread_utilization_ratio
    process_set = Sidekiq::ProcessSet.new
    busy_threads = process_set.sum { |p| p['busy'] }
    total_concurrency = process_set.total_concurrency.to_f
    return 0.0 if total_concurrency.zero?

    busy_threads / total_concurrency
  end

  # ---------- AWS env detection & metadata ----------
  def aws_environment?
    # IMDSv2 request for instance-id
    !!metadata_get('/latest/meta-data/instance-id')
  rescue StandardError
    false
  end

  def detect_aws_metadata
    return unless aws_environment?

    set_instance_identity_data
    set_basic_instance_id
    set_auto_scaling_group_name
    log_aws_metadata
  rescue StandardError => e
    Rails.logger.error "AWS metadata detection failed: #{e.message}"
  end

  def set_instance_identity_data
    doc = metadata_get('/latest/dynamic/instance-identity/document')
    return unless doc

    parsed_data = parse_instance_identity_document(doc)
    update_environment_variables(parsed_data)
  end

  def parse_instance_identity_document(doc)
    JSON.parse(doc)
  rescue StandardError
    {}
  end

  def update_environment_variables(parsed_data)
    ENV['AWS_REGION']     ||= parsed_data['region']
    ENV['AWS_ACCOUNT_ID'] ||= parsed_data['accountId']
    ENV['AWS_AZ']         ||= parsed_data['availabilityZone']
  end

  def set_basic_instance_id
    ENV['AWS_INSTANCE_ID'] ||= metadata_get('/latest/meta-data/instance-id')
  end

  def set_auto_scaling_group_name
    ENV['AWS_AUTO_SCALING_GROUP_NAME'] ||= 'csdb-asg-1'
  end

  def log_aws_metadata
    Rails.logger.info "AWS metadata: REGION=#{ENV.fetch('AWS_REGION', nil)}, " \
                      "INSTANCE_ID=#{ENV.fetch('AWS_INSTANCE_ID', nil)}, " \
                      "ASG=#{ENV.fetch('AWS_AUTO_SCALING_GROUP_NAME', nil)}"
  end

  # ---------- CloudWatch client ----------
  def cloudwatch_client
    self.class.client_mutex.synchronize do
      if self.class.cached_client.nil? || client_needs_refresh?
        Rails.logger.info 'Creating new AWS CloudWatch client'
        self.class.cached_client = Aws::CloudWatch::Client.new(
          region: ENV.fetch('AWS_REGION', nil),
          credentials: Aws::InstanceProfileCredentials.new(retries: 3)
        )
        self.class.client_created_at = Time.current
      end
      self.class.cached_client
    end
  rescue StandardError => e
    Rails.logger.error "Failed to create CloudWatch client: #{e.message}"
    Aws::CloudWatch::Client.new(region: ENV.fetch('AWS_REGION', nil))
  end

  def client_needs_refresh?
    self.class.client_created_at.nil? || (Time.current - self.class.client_created_at) > CLIENT_REFRESH_INTERVAL
  end

  # ---------- Metric publish ----------
  def send_metrics_to_cloudwatch(ratio)
    dimensions = build_cloudwatch_dimensions
    publish_metric_data(ratio, dimensions)
    log_metric_success(ratio)
  rescue StandardError => e
    handle_cloudwatch_error(e)
  end

  def build_cloudwatch_dimensions
    dims = [{ name: 'InstanceId', value: ENV.fetch('AWS_INSTANCE_ID', nil) }]
    add_asg_dimension(dims) if ENV['AWS_AUTO_SCALING_GROUP_NAME'].present?
    dims
  end

  def add_asg_dimension(dimensions)
    dimensions << { name: 'AutoScalingGroupName', value: ENV.fetch('AWS_AUTO_SCALING_GROUP_NAME', nil) }
  end

  def publish_metric_data(ratio, dimensions)
    cloudwatch_client.put_metric_data(
      namespace: 'Custom/Sidekiq',
      metric_data: [build_metric_data_entry(ratio, dimensions)]
    )
  end

  def build_metric_data_entry(ratio, dimensions)
    {
      metric_name: 'ThreadUtilization',
      dimensions: dimensions,
      timestamp: Time.now.utc,
      value: ratio,
      unit: 'None',
      storage_resolution: 60 # 1-minute high-resolution metric
    }
  end

  def log_metric_success(ratio)
    Rails.logger.info "Sidekiq metric sent to CloudWatch: #{ratio.round(3)}"
  end

  def handle_cloudwatch_error(error)
    Rails.logger.error "CloudWatch metrics failed: #{error.class} - #{error.message}"
    clear_client_cache_if_auth_error(error)
  end

  def clear_client_cache_if_auth_error(error)
    return unless auth_error?(error)

    Rails.logger.info 'Clearing AWS client cache due to authentication error'
    self.class.clear_client_cache!
  end

  def auth_error?(error)
    /(auth|credential|ExpiredToken|UnrecognizedClientException)/i.match?(error.message)
  end

  # ---------- IMDSv2 helpers ----------
  def metadata_get(path)
    Timeout.timeout(METADATA_TIMEOUT) do
      token = imds_token
      uri = URI("http://169.254.169.254#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = METADATA_TIMEOUT
      http.read_timeout = METADATA_TIMEOUT

      req = Net::HTTP::Get.new(uri)
      req['X-aws-ec2-metadata-token'] = token if token
      res = http.request(req)
      return nil unless res.is_a?(Net::HTTPSuccess)

      res.body
    end
  end

  def imds_token
    Timeout.timeout(METADATA_TIMEOUT) do
      uri = URI('http://169.254.169.254/latest/api/token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = METADATA_TIMEOUT
      http.read_timeout = METADATA_TIMEOUT

      req = Net::HTTP::Put.new(uri)
      req['X-aws-ec2-metadata-token-ttl-seconds'] = '60'
      res = http.request(req)
      return res.body if res.is_a?(Net::HTTPSuccess)

      nil
    end
  rescue StandardError
    nil
  end
end
# rubocop:enable Metrics/ClassLength
