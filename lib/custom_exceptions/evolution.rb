# frozen_string_literal: true

module CustomExceptions::Evolution
  class Base < CustomExceptions::Base
    def error_code
      'EVOLUTION_UNKNOWN_ERROR'
    end

    def to_hash
      {
        message: message,
        error_code: error_code,
        http_status: http_status,
        timestamp: Time.current.iso8601
      }
    end
  end

  class ServiceUnavailable < Base
    def message
      I18n.t('errors.evolution.service_unavailable')
    end

    def http_status
      503
    end

    def error_code
      'EVOLUTION_SERVICE_UNAVAILABLE'
    end
  end

  class AuthenticationError < Base
    def message
      I18n.t('errors.evolution.authentication_failed')
    end

    def http_status
      401
    end

    def error_code
      'EVOLUTION_AUTH_FAILED'
    end
  end

  class NetworkTimeout < Base
    def message
      I18n.t('errors.evolution.network_timeout')
    end

    def http_status
      504
    end

    def error_code
      'EVOLUTION_NETWORK_TIMEOUT'
    end
  end

  class InstanceConflict < Base
    def message
      I18n.t('errors.evolution.instance_exists', instance_name: @data[:instance_name] || 'Unknown')
    end

    def http_status
      409
    end

    def error_code
      'EVOLUTION_INSTANCE_EXISTS'
    end
  end

  class InvalidConfiguration < Base
    def message
      I18n.t('errors.evolution.invalid_configuration', details: @data[:details] || 'Unknown error')
    end

    def http_status
      400
    end

    def error_code
      'EVOLUTION_INVALID_CONFIG'
    end
  end

  class InstanceCreationFailed < Base
    def message
      I18n.t('errors.evolution.instance_creation_failed', reason: @data[:reason] || 'Unknown reason')
    end

    def http_status
      422
    end

    def error_code
      'EVOLUTION_INSTANCE_CREATION_FAILED'
    end
  end

  class ConnectionRefused < Base
    def message
      I18n.t('errors.evolution.connection_refused')
    end

    def http_status
      503
    end

    def error_code
      'EVOLUTION_CONNECTION_REFUSED'
    end
  end

  def self.from_http_error(error, context = {})
    case error
    when Net::TimeoutError, Net::ReadTimeout, Net::OpenTimeout
      NetworkTimeout.new(context)
    when Errno::ECONNREFUSED, SocketError
      ConnectionRefused.new(context)
    when HTTParty::ResponseError
      map_http_response_error(error, context)
    else
      InvalidConfiguration.new(context.merge(details: error.message))
    end
  end

  def self.map_http_response_error(error, context)
    case error.response&.code
    when 401, 403
      AuthenticationError.new(context)
    when 409
      InstanceConflict.new(context)
    when 422
      InstanceCreationFailed.new(context.merge(reason: error.response.body))
    when 503
      ServiceUnavailable.new(context)
    else
      InvalidConfiguration.new(context.merge(details: error.message))
    end
  end
end
