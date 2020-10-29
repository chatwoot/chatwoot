module ExceptionList
  URI_EXCEPTIONS = [Errno::ETIMEDOUT, Errno::ECONNREFUSED, URI::InvalidURIError, Net::OpenTimeout, SocketError].freeze
  REST_CLIENT_EXCEPTIONS = [RestClient::NotFound, RestClient::GatewayTimeout, RestClient::BadRequest, RestClient::MethodNotAllowed].freeze
end
