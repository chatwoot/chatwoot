require 'sidekiq/api'
require 'google/cloud/monitoring/v3'
require 'net/http'
require 'timeout'

class SidekiqThreadUtilizationMonitoringJob < ApplicationJob
  queue_as :scheduled_jobs

  # Add jid attribute accessor for Sidekiq compatibility
  attr_accessor :jid

  # HTTP timeout for metadata requests (seconds)
  METADATA_TIMEOUT = 10.seconds
  # Google Cloud API timeout (seconds)
  API_TIMEOUT = 10.seconds
  # Total job timeout (seconds)
  TOTAL_JOB_TIMEOUT = 12.seconds

  # Class-level client cache with thread safety
  @client_mutex = Mutex.new
  @cached_client = nil
  @client_created_at = nil
  # Refresh client every hour to handle token expiration
  CLIENT_REFRESH_INTERVAL = 1.hour

  class << self
    attr_accessor :client_mutex, :cached_client, :client_created_at

    # Class method to clear the cached client (useful for testing or manual refresh)
    def clear_client_cache!
      @client_mutex.synchronize do
        @cached_client = nil
        @client_created_at = nil
      end
    end
  end

  def perform
    Timeout.timeout(TOTAL_JOB_TIMEOUT) do
      perform_job
    end
  rescue Timeout::Error
    Rails.logger.error 'timeout reached for worker'
  end

  def perform_job
    return unless should_run?

    # Auto-detect Google Cloud environment variables if not set
    detect_google_cloud_metadata

    return unless required_env_vars_present?

    ratio = calculate_thread_utilization_ratio
    send_metrics_to_google_cloud(ratio)
  rescue StandardError => e
    Rails.logger.error "SidekiqThreadUtilizationMonitoringJob: #{e.class} - #{e.message}"
  end

  private

  def should_run?
    # Only run if we're in a Google Cloud environment or if required env vars are manually set
    google_cloud_environment? || required_env_vars_present?
  end

  def google_cloud_environment?
    # Check if we're running on Google Compute Engine
    metadata('instance/id')
    true
  rescue StandardError
    false
  end

  def detect_google_cloud_metadata
    return unless google_cloud_environment?

    # Only set if not already present
    ENV['GOOGLE_CLOUD_PROJECT'] ||= metadata('project/project-id')
    ENV['GCP_INSTANCE_ID'] ||= metadata('instance/id')

    instance_full_zone = metadata('instance/zone')
    # zone value comes back like "projects/123/zones/asia-south1-a"
    ENV['GCP_ZONE'] ||= instance_full_zone.split('/').last

    Rails.logger.info "GCP metadata: PROJECT=#{ENV.fetch('GOOGLE_CLOUD_PROJECT', nil)}, " \
                      "ZONE=#{ENV.fetch('GCP_ZONE', nil)}, " \
                      "INSTANCE_ID=#{ENV.fetch('GCP_INSTANCE_ID', nil)}"
  rescue StandardError => e
    Rails.logger.error "GCP metadata detection failed: #{e.message}"
  end

  def required_env_vars_present?
    ENV['GOOGLE_CLOUD_PROJECT'].present? &&
      ENV['GCP_ZONE'].present? &&
      ENV['GCP_INSTANCE_ID'].present?
  end

  def metadata(path)
    Timeout.timeout(METADATA_TIMEOUT) do
      uri = URI("http://metadata.google.internal/computeMetadata/v1/#{path}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = METADATA_TIMEOUT
      http.read_timeout = METADATA_TIMEOUT

      req = Net::HTTP::Get.new(uri)
      req['Metadata-Flavor'] = 'Google'
      http.request(req).body
    end
  end

  def calculate_thread_utilization_ratio
    process_set = Sidekiq::ProcessSet.new
    busy_threads = process_set.sum { |p| p['busy'] }
    total_concurrency = process_set.total_concurrency.to_f

    return 0.0 if total_concurrency.zero?

    busy_threads / total_concurrency
  end

  # Get or create a cached Google Cloud client
  def monitoring_client
    self.class.client_mutex.synchronize do
      # Check if we need to refresh the client
      if self.class.cached_client.nil? || client_needs_refresh?
        Rails.logger.info 'Creating new Google Cloud Monitoring client'
        self.class.cached_client = Google::Cloud::Monitoring::V3::MetricService::Client.new
        self.class.client_created_at = Time.current
      end

      self.class.cached_client
    end
  rescue StandardError => e
    Rails.logger.error "Failed to create monitoring client: #{e.message}"
    # If cached client fails, try creating a new one directly
    Google::Cloud::Monitoring::V3::MetricService::Client.new
  end

  def client_needs_refresh?
    return true if self.class.client_created_at.nil?

    Time.current - self.class.client_created_at > CLIENT_REFRESH_INTERVAL
  end

  def send_metrics_to_google_cloud(ratio)
    Timeout.timeout(API_TIMEOUT) do
      client = monitoring_client
      project = "projects/#{ENV.fetch('GOOGLE_CLOUD_PROJECT', nil)}"
      time_series = build_time_series(ratio)

      client.create_time_series name: project, time_series: [time_series]
    end

    Rails.logger.info "Sidekiq metric sent: #{ratio.round(3)}"

    # Clean up gcloud helper processes after successful metric send
    cleanup_gcloud_processes
  rescue StandardError => e
    Rails.logger.error "GCP metrics failed: #{e.class} - #{e.message}"

    # If we get an authentication error, clear the cache so next run gets a fresh client
    if e.message.include?('authentication') || e.message.include?('credential')
      Rails.logger.info 'Clearing client cache due to authentication error'
      self.class.clear_client_cache!
    end

    cleanup_gcloud_processes
  end

  def build_time_series(ratio)
    Google::Cloud::Monitoring::V3::TimeSeries.new(
      metric: build_metric,
      resource: build_monitored_resource,
      points: [build_data_point(ratio)]
    )
  end

  def build_metric
    Google::Api::Metric.new(
      type: 'custom.googleapis.com/sidekiq/thread_utilization'
    )
  end

  def build_monitored_resource
    Google::Api::MonitoredResource.new(
      type: 'gce_instance',
      labels: {
        'project_id' => ENV.fetch('GOOGLE_CLOUD_PROJECT', nil).to_s,
        'zone' => ENV.fetch('GCP_ZONE', nil).to_s,
        'instance_id' => ENV.fetch('GCP_INSTANCE_ID', nil).to_s
      }
    )
  end

  def build_data_point(ratio)
    Google::Cloud::Monitoring::V3::Point.new(
      value: Google::Cloud::Monitoring::V3::TypedValue.new(double_value: ratio),
      interval: Google::Cloud::Monitoring::V3::TimeInterval.new(
        end_time: Google::Protobuf::Timestamp.new(seconds: Time.now.to_i)
      )
    )
  end

  def cleanup_gcloud_processes
    # Find gcloud config-helper processes and kill them more aggressively
    begin
      `sudo pkill -9 -f "gcloud.*config.*config-helper"`
    rescue StandardError
      nil
    end

    Rails.logger.debug 'Cleaned up gcloud helper processes'
  rescue StandardError => e
    Rails.logger.warn "Failed to cleanup gcloud processes: #{e.message}"
  end
end
