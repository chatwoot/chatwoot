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

        render json: {
          status: 'success',
          blob_id: blob.id,
          file_size: file_size,
          file_size_mb: (file_size / 1024.0 / 1024.0).round(2),
          upload_time: upload_time,
          throughput_mbps: file_size > 0 ? ((file_size * 8.0 / 1024.0 / 1024.0) / (upload_time / 1000.0)).round(2) : 0,
          download_url: rails_blob_url(blob, disposition: 'attachment'),
          storage_service: ActiveStorage::Blob.service.name
        }
      else
        render json: {
          status: 'error',
          error: 'No file provided'
        }, status: :bad_request
      end
    rescue StandardError => e
      render json: {
        status: 'error',
        error: e.message,
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
end
