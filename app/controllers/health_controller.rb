# Inherits from ActionController::Base to skip all middleware,
# authentication, and callbacks. Used for health checks
class HealthController < ActionController::Base # rubocop:disable Rails/ApplicationController
  # Liveness: the process is up and serving HTTP.
  def show
    render json: { status: 'woot' }
  end

  # Readiness: only succeeds when this instance can reach Postgres and Redis,
  # so a container is not marked healthy (and does not replace a good one) while its dependencies are down.
  def ready
    if database_ready? && redis_ready?
      render json: { status: 'ready' }
    else
      render json: { status: 'unavailable' }, status: :service_unavailable
    end
  end

  private

  def database_ready?
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue StandardError
    false
  end

  def redis_ready?
    redis = Redis.new(Redis::Config.app)
    redis.ping == 'PONG'
  rescue StandardError
    false
  ensure
    redis&.close
  end
end
