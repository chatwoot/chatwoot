require 'sidekiq/api'
require 'google/cloud/monitoring/v3'
require 'net/http'

class SidekiqThreadUtilizationMonitoringJob < ApplicationJob
  queue_as :scheduled_jobs

  # Add jid attribute accessor for Sidekiq compatibility
  attr_accessor :jid

  def perform
    return unless should_run?

    # Auto-detect Google Cloud environment variables if not set
    detect_google_cloud_metadata

    return unless required_env_vars_present?

    ratio = calculate_thread_utilization_ratio
    send_metrics_to_google_cloud(ratio)
  rescue StandardError => e
    Rails.logger.error "SidekiqThreadUtilizationMonitoringJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
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

    ENV['INSTANCE_ID'] ||= metadata('instance/id')

    Rails.logger.info "Auto-detected Google Cloud metadata: PROJECT=#{ENV.fetch('GOOGLE_CLOUD_PROJECT',
                                                                                nil)}, ZONE=#{ENV.fetch('GCP_ZONE',
                                                                                                        nil)}, INSTANCE_ID=#{ENV.fetch('INSTANCE_ID',
                                                                                                                                       nil)}"
  rescue StandardError => e
    Rails.logger.error "Failed to detect Google Cloud metadata: #{e.message}"
  end

  def required_env_vars_present?
    ENV['GOOGLE_CLOUD_PROJECT'].present? &&
      ENV['INSTANCE_ID'].present? &&
      ENV['GCP_ZONE'].present?
  end

  def metadata(path)
    uri = URI("http://metadata.google.internal/computeMetadata/v1/#{path}")
    req = Net::HTTP::Get.new(uri)
    req['Metadata-Flavor'] = 'Google'
    Net::HTTP.start(uri.host, uri.port) { |h| h.request(req).body }
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
    client = Google::Cloud::Monitoring::V3::MetricService::Client.new
    project = "projects/#{ENV.fetch('GOOGLE_CLOUD_PROJECT', nil)}"

    series = {
      metric: {
        type: 'custom.googleapis.com/sidekiq/thread_utilization'
      },
      resource: {
        type: 'gce_instance',
        labels: {
          'project_id' => ENV.fetch('GOOGLE_CLOUD_PROJECT', nil).to_s,
          'instance_id' => ENV.fetch('INSTANCE_ID', nil).to_s,
          'zone' => ENV.fetch('GCP_ZONE', nil).to_s
        }
      },
      points: [
        {
          value: { double_value: ratio },
          interval: { end_time: { seconds: Time.now.to_i } }
        }
      ]
    }

    client.create_time_series name: project, time_series: [series]

    Rails.logger.info "Sidekiq thread utilization metric sent: #{ratio}"
  rescue StandardError => e
    Rails.logger.error "Failed to send metrics to Google Cloud: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
  # rubocop:enable Metrics/MethodLength
end

SidekiqThreadUtilizationMonitoringJob.prepend_mod_with('SidekiqThreadUtilizationMonitoringJob')
