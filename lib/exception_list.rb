module ExceptionList
  URI_EXCEPTIONS = [Errno::ETIMEDOUT, Errno::ECONNREFUSED, URI::InvalidURIError, SocketError].freeze
  REST_CLIENT_EXCEPTIONS = [RestClient::NotFound, RestClient::GatewayTimeout, RestClient::BadRequest].freeze
end
