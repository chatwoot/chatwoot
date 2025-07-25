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

    instance_full_zone = metadata('instance/zone')
    # zone value comes back like "projects/123/zones/asia-south1-a"
    ENV['GCP_ZONE'] ||= instance_full_zone.split('/').last

    Rails.logger.info "GCP metadata: PROJECT=#{ENV.fetch('GOOGLE_CLOUD_PROJECT', nil)}, " \
                      "ZONE=#{ENV.fetch('GCP_ZONE', nil)}"
  rescue StandardError => e
    Rails.logger.error "GCP metadata detection failed: #{e.message}"
  end

  def required_env_vars_present?
    ENV['GOOGLE_CLOUD_PROJECT'].present? &&
      ENV['GCP_ZONE'].present?
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

  # rubocop:disable Metrics/MethodLength
  def send_metrics_to_google_cloud(ratio)
    Timeout.timeout(API_TIMEOUT) do
      client = Google::Cloud::Monitoring::V3::MetricService::Client.new
      project = "projects/#{ENV.fetch('GOOGLE_CLOUD_PROJECT', nil)}"

      time_series = Google::Cloud::Monitoring::V3::TimeSeries.new(
        metric: Google::Api::Metric.new(
          type: 'custom.googleapis.com/sidekiq/thread_utilization'
        ),
        resource: Google::Api::MonitoredResource.new(
          type: 'gce_instance',
          labels: {
            'project_id' => ENV.fetch('GOOGLE_CLOUD_PROJECT', nil).to_s,
            'zone' => ENV.fetch('GCP_ZONE', nil).to_s
          }
        ),
        points: [
          Google::Cloud::Monitoring::V3::Point.new(
            value: Google::Cloud::Monitoring::V3::TypedValue.new(double_value: ratio),
            interval: Google::Cloud::Monitoring::V3::TimeInterval.new(
              end_time: Google::Protobuf::Timestamp.new(seconds: Time.now.to_i)
            )
          )
        ]
      )

      client.create_time_series name: project, time_series: [time_series]
    end

    Rails.logger.info "Sidekiq metric sent: #{ratio.round(3)}"
  rescue StandardError => e
    Rails.logger.error "GCP metrics failed: #{e.class} - #{e.message}"
  end
  # rubocop:enable Metrics/MethodLength
end
