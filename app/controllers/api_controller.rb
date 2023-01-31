class ApiController < ApplicationController
  skip_before_action :set_current_user, only: [:index]

  def index
    render json: { version: Chatwoot.config[:version],
                   timestamp: Time.now.utc.to_formatted_s(:db),
                   queue_services: redis_status,
                   data_services: postgres_status }
  end

  private

  def redis_status
    r = Redis.new(Redis::Config.app)
    return 'ok' if r.ping
  rescue Redis::CannotConnectError
    'failing'
  end

  def postgres_status
    ActiveRecord::Base.connection.active? ? 'ok' : 'failing'
  rescue ActiveRecord::ConnectionNotEstablished
    'failing'
  end
end
