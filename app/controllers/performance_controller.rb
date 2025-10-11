class PerformanceController < PublicController
  def index
    # Public performance testing page
    render layout: false
  end

  def ping
    # Simple ping endpoint for latency testing
    render json: {
      timestamp: Time.current.to_i,
      server_time: Time.current.iso8601,
      status: 'ok'
    }
  end

  def database
    # Test database connectivity
    start_time = Time.current
    begin
      # Simple query to test DB connection
      ActiveRecord::Base.connection.execute('SELECT 1')
      query_time = ((Time.current - start_time) * 1000).round(2)

      render json: {
        status: 'connected',
        response_time: query_time,
        adapter: ActiveRecord::Base.connection.adapter_name,
        pool_size: ActiveRecord::Base.connection_pool.size,
        active_connections: ActiveRecord::Base.connection_pool.connections.count
      }
    rescue StandardError => e
      render json: {
        status: 'error',
        error: e.message,
        response_time: ((Time.current - start_time) * 1000).round(2)
      }, status: :service_unavailable
    end
  end

  def redis
    # Test Redis connectivity
    start_time = Time.current
    begin
      # Test Redis connection with PING command
      result = Redis.new(url: ENV.fetch('REDIS_URL', nil)).ping

      response_time = ((Time.current - start_time) * 1000).round(2)

      render json: {
        status: 'connected',
        response_time: response_time,
        ping_result: result
      }
    rescue StandardError => e
      render json: {
        status: 'error',
        error: e.message,
        response_time: ((Time.current - start_time) * 1000).round(2)
      }, status: :service_unavailable
    end
  end

  def upload_file
    # Test file upload to storage (S3/GCS/Azure)
    start_time = Time.current
    begin
      if params[:file].present?
        uploaded_file = params[:file]
        file_size = uploaded_file.size

        # Create a temporary ActiveStorage blob for testing
        blob = ActiveStorage::Blob.create_and_upload!(
          io: uploaded_file,
          filename: "perf_test_#{SecureRandom.hex(8)}_#{uploaded_file.original_filename}",
          content_type: uploaded_file.content_type
        )

        upload_time = ((Time.current - start_time) * 1000).round(2)

        # Get storage region based on service type
        region = case ENV.fetch('ACTIVE_STORAGE_SERVICE', 'local')
                 when 'amazon'
                   ENV.fetch('AWS_REGION', 'unknown')
                 when 's3_compatible'
                   ENV.fetch('STORAGE_REGION', 'unknown')
                 when 'google'
                   ENV.fetch('GCS_PROJECT', 'unknown')
                 when 'microsoft'
                   ENV.fetch('AZURE_STORAGE_ACCOUNT_NAME', 'unknown')
                 else
                   'local'
                 end

        # Use direct S3 URL instead of Rails redirect URL for multi-pod compatibility
        download_url = blob.service.url(blob.key, expires_in: 1.hour, disposition: 'attachment', filename: blob.filename, content_type: blob.content_type)

        render json: {
          status: 'success',
          blob_id: blob.id,
          file_size: file_size,
          file_size_mb: (file_size / 1024.0 / 1024.0).round(2),
          server_upload_time: upload_time,
          throughput_mbps: file_size > 0 ? ((file_size * 8.0 / 1024.0 / 1024.0) / (upload_time / 1000.0)).round(2) : 0,
          download_url: download_url,
          storage_service: ActiveStorage::Blob.service.name,
          region: region
        }
      else
        render json: {
          status: 'error',
          error: 'No file provided'
        }, status: :bad_request
      end
    rescue StandardError => e
      Rails.logger.error "Performance upload error: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        status: 'error',
        error: e.message,
        error_class: e.class.name,
        upload_time: ((Time.current - start_time) * 1000).round(2)
      }, status: :internal_server_error
    end
  end

  def cleanup_file
    # Delete uploaded test file
    begin
      blob = ActiveStorage::Blob.find_by(id: params[:blob_id])
      if blob
        blob.purge
        render json: { status: 'success', message: 'File deleted' }
      else
        render json: { status: 'error', error: 'File not found' }, status: :not_found
      end
    rescue StandardError => e
      render json: { status: 'error', error: e.message }, status: :internal_server_error
    end
  end

  def sample_file
    # Serve sample file for download testing
    file_path = Rails.root.join('public', 'perf_samples', 'sample.mp4')

    if File.exist?(file_path)
      send_file file_path, type: 'video/mp4', disposition: 'attachment', filename: 'sample.mp4'
    else
      render json: { status: 'error', error: 'Sample file not found' }, status: :not_found
    end
  end

  def log_test_results
    # Log performance test results to Sentry
    begin
      test_data = params[:test_data]

      if test_data.blank?
        render json: { status: 'error', error: 'No test data provided' }, status: :bad_request
        return
      end

      # Log to Sentry Logs (structured, searchable logs in Sentry)
      if defined?(Sentry) && ENV['SENTRY_DSN'].present?
        # Use Sentry.logger for structured logs (requires sentry-ruby >= 5.24.0)
        Sentry.logger.info(
          'Performance test completed - test_type: %{test_type}, server_latency: %{server_latency}ms, db: %{db_time}ms, redis: %{redis_time}ms',
          test_type: test_data[:test_type] || 'all_tests',
          environment: ENV.fetch('APP_ENVIRONMENT', Rails.env),
          timestamp: test_data[:timestamp],
          # Server metrics
          server_latency: test_data.dig(:server, :average),
          server_packet_loss: test_data.dig(:server, :packetLoss),
          # Database metrics
          db_time: test_data.dig(:database, :response_time),
          db_status: test_data.dig(:database, :status),
          # Redis metrics
          redis_time: test_data.dig(:redis, :response_time),
          redis_status: test_data.dig(:redis, :status),
          # WebSocket metrics
          websocket_status: test_data.dig(:websocket, :status),
          websocket_connection_time: test_data.dig(:websocket, :initialConnection, :connectionTime),
          # Browser info
          browser: test_data.dig(:browser, :userAgent),
          # Network info
          network_type: test_data.dig(:network, :effectiveType),
          network_downlink: test_data.dig(:network, :downlink),
          # File transfer metrics
          file_upload_time: test_data.dig(:fileTransfer, :upload, :serverUploadTime),
          file_download_time: test_data.dig(:fileTransfer, :download, :downloadTime),
          file_upload_throughput: test_data.dig(:fileTransfer, :upload, :throughputMbps),
          file_download_throughput: test_data.dig(:fileTransfer, :download, :throughputMbps)
        )
        render json: { status: 'success', message: 'Test results logged to Sentry Logs' }
      else
        Rails.logger.info "Performance test completed (Sentry not configured): #{test_data.inspect}"
        render json: { status: 'success', message: 'Test results logged locally (Sentry not configured)' }
      end
    rescue StandardError => e
      Rails.logger.error "Failed to log test results to Sentry: #{e.message}"
      render json: { status: 'error', error: e.message }, status: :internal_server_error
    end
  end
end
