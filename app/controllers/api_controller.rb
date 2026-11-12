class ApiController < ApplicationController
  # Milliseconds a health probe may wait for the database before reporting it as failing.
  POSTGRES_STATUS_TIMEOUT_MS = 2000

  skip_before_action :set_current_user, only: [:index]

  def index
    render json: { version: Chatwoot.config[:version],
                   timestamp: Time.now.utc.to_fs(:db),
                   queue_services: redis_status,
                   data_services: postgres_status,
                   mobile_app: { min_version: mobile_app_min_versions } }
  end

  private

  def mobile_app_min_versions
    { ios: GlobalConfig.get_value('MOBILE_APP_MIN_IOS_VERSION').presence,
      android: GlobalConfig.get_value('MOBILE_APP_MIN_ANDROID_VERSION').presence }
  rescue Redis::BaseError, ConnectionPool::TimeoutError, ActiveRecord::ActiveRecordError
    { ios: nil, android: nil }
  end

  def redis_status
    r = Redis.new(Redis::Config.app)
    return 'ok' if r.ping
  rescue Redis::CannotConnectError
    'failing'
  end

  # Runs a real query instead of `connection.active?`: since Rails 7.1 pool connections connect lazily, and
  # `active?` returns false for a pooled connection that has never been used without contacting the database.
  # The connection reaper flushes idle connections (idle_timeout, 300 s by default), so a monitor polling this
  # endpoint on a similar cadence intermittently read "failing" from a healthy database.
  # SET LOCAL keeps the short timeout inside this transaction only; the pooled connection is left unchanged.
  def postgres_status
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.transaction do
        connection.execute("SET LOCAL statement_timeout = #{POSTGRES_STATUS_TIMEOUT_MS}")
        connection.select_value('SELECT 1') == 1 ? 'ok' : 'failing'
      end
    end
  rescue ActiveRecord::ActiveRecordError, PG::Error
    'failing'
  end
end