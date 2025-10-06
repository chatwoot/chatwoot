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
end
