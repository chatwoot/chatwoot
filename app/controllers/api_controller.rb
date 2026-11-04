class ApiController < ApplicationController
  # Advertised so clients can detect optional API behaviour without version sniffing.
  # message_client_message_id_text: message creation accepts a client_message_id for
  # attachment-free text replies and private notes, and replays the original message
  # when that key is reused.
  CAPABILITIES = %w[message_client_message_id_text].freeze

  skip_before_action :set_current_user, only: [:index]

  def index
    render json: { version: Chatwoot.config[:version],
                   capabilities: CAPABILITIES,
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

  def postgres_status
    ActiveRecord::Base.connection.active? ? 'ok' : 'failing'
  rescue ActiveRecord::ConnectionNotEstablished
    'failing'
  end
end
