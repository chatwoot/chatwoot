class ApiController < ApplicationController
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
    configs = GlobalConfig.get('MOBILE_APP_MIN_IOS_VERSION', 'MOBILE_APP_MIN_ANDROID_VERSION')
    { ios: configs['MOBILE_APP_MIN_IOS_VERSION'].presence, android: configs['MOBILE_APP_MIN_ANDROID_VERSION'].presence }
  rescue Redis::BaseError, ActiveRecord::ActiveRecordError
    { ios: nil, android: nil }
  end

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
